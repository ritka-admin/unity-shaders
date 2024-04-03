using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class radiance_cascades_2d : MonoBehaviour
{
    private Material cascade_pass;
    private Material occlusion_pass;
    private Texture2D OcclusionTexture;

    [Range(0, 512)]
    public int zeroResolution = 256;

    [Range(1, 100)]
    public int zeroDirectionCount = 4;

    [Range(4, 256)]
    public int zeroIntervalPixels = 8;

    [Range(2, 4)]
    public int radiusScaleFactor = 2;

    [Range(2, 4)]
    public int branchFactor = 2;

    [Range(1, 9)]
    public int nCascades = 5;

    [Range(0, 1)]
    public float skyIntensity = 0;

    [Range(1, 90)]
    public float sunSize = 20;

    [Range(0, 1)]
    public float sunIntensity = 1;

    [Range(0, 360)]
    public float sunAngle = 0;

    [Range(0f, 100f)] 
    public float contrast = 1f;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        cascade_pass = new Material( Shader.Find("Hidden/cascade_pass") );
        occlusion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );

        OcclusionTexture = Resources.Load<Texture2D>("my_game2");
        OcclusionTexture.wrapMode = TextureWrapMode.Clamp;

        // fill and merge all cascades
        RenderTexture PrevCascade = null;

        // first prevs correspond with the last
        int prevCascadeResolution = zeroResolution >> nCascades - 1;
        int prevCascadeDirCount = (int) Mathf.Pow(branchFactor, nCascades - 1) * zeroDirectionCount;
        float prevCascadeInnerRadius = Mathf.Pow(radiusScaleFactor, nCascades - 2) * zeroIntervalPixels;
        float prevCascadeOuterRadius = Mathf.Pow(radiusScaleFactor, nCascades - 1) * zeroIntervalPixels;

        for (int i = nCascades - 1; i >= 0; --i) 
        {
            int curR = i == nCascades - 1 ? prevCascadeResolution : prevCascadeResolution * 2;
            int curD = i == nCascades - 1 ? prevCascadeDirCount : prevCascadeDirCount / branchFactor;
            float curInnerRadius = i == nCascades - 1 ? prevCascadeInnerRadius : prevCascadeInnerRadius / radiusScaleFactor;
            float curOuterRadius = i == nCascades - 1 ? prevCascadeOuterRadius : prevCascadeInnerRadius;

            RenderTexture RadianceTexture = RenderTexture.GetTemporary(curR * curD, curR, 0, RenderTextureFormat.RFloat);
            RadianceTexture.filterMode = FilterMode.Bilinear;
            RadianceTexture.wrapMode = TextureWrapMode.Clamp;

            cascade_pass.SetTexture("_PrevCascade", PrevCascade);
            cascade_pass.SetInt("PrevCascadeDirCount", prevCascadeDirCount);
            cascade_pass.SetInt("PrevCascadeResolution", prevCascadeResolution);
            cascade_pass.SetInt("NCascades", nCascades);
            cascade_pass.SetInt("BranchFactor", branchFactor);
            cascade_pass.SetInt("RadiusScaleFactor", radiusScaleFactor);
            cascade_pass.SetInt("ZeroIntervalPixels", zeroIntervalPixels);
            cascade_pass.SetFloat("CurInnerRadius", curInnerRadius);
            cascade_pass.SetFloat("CurOuterRadius", curOuterRadius);
            cascade_pass.SetInt("CurCascade", i);
            cascade_pass.SetInt("DirectionCount", curD);
            cascade_pass.SetFloat("OutputTexWidth", RadianceTexture.width);
            cascade_pass.SetFloat("SkyIntensity", skyIntensity);
            cascade_pass.SetFloat("SunDirectionX", Mathf.Cos(Mathf.Deg2Rad * sunAngle));
            cascade_pass.SetFloat("SunDirectionY", Mathf.Sin(Mathf.Deg2Rad * sunAngle));
            cascade_pass.SetFloat("SunSize", Mathf.Cos(Mathf.Deg2Rad * sunSize));
            cascade_pass.SetFloat("SunIntensity", sunIntensity * 360 / sunSize);

            Graphics.Blit(OcclusionTexture, RadianceTexture, cascade_pass);
            RenderTexture.ReleaseTemporary(PrevCascade);
            
            PrevCascade = RadianceTexture;
            prevCascadeDirCount = curD;
            prevCascadeResolution = curR;
            prevCascadeInnerRadius = curInnerRadius;
            prevCascadeOuterRadius = curOuterRadius;
        }

        // uniforms for resulting pass
        occlusion_pass.SetTexture("_RadianceTex", PrevCascade);
        occlusion_pass.SetInt("DirectionCount", zeroDirectionCount);
        occlusion_pass.SetFloat("contrast", contrast);

        Graphics.Blit(OcclusionTexture, destination, occlusion_pass);

        // release textures
        RenderTexture.ReleaseTemporary(PrevCascade);
    }
}
