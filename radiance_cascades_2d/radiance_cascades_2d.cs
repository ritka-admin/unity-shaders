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
    public int zeroW = 256;

    [Range(4, 100)]
    public int zeroDirectionCount = 4;

    [Range(1, 90)]
    public float sunSize = 20;

    [Range(0, 1)]
    public float skyIntensity = 0;

    [Range(0, 1)]
    public float sunIntensity = 1;

    [Range(0, 360)]
    public float sunAngle = 0;


    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {

        cascade_pass = new Material( Shader.Find("Hidden/cascade_pass") );
        occlusion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );

        OcclusionTexture = Resources.Load<Texture2D>("occlusion");
        OcclusionTexture.wrapMode = TextureWrapMode.Clamp;

        // fill and merge all cascades
        int nCascades = 7;
        RenderTexture PrevCascade = null;

        for (int i = nCascades - 1; i >= 0; --i) 
        {
            int curW = zeroW >> i;
            int curD = zeroDirectionCount << i;

            // Debug.Log(i + " , w:" + curW + ", d: " + curD);

            RenderTexture RadianceTexture = RenderTexture.GetTemporary(curW * curD, curW, 0, RenderTextureFormat.RFloat);
            RadianceTexture.filterMode = FilterMode.Bilinear;
            RadianceTexture.wrapMode = TextureWrapMode.Clamp;

            cascade_pass.SetTexture("_PrevCascade", PrevCascade);
            cascade_pass.SetInt("NCascades", nCascades);
            cascade_pass.SetInt("CurCascade", i);
            cascade_pass.SetInt("W", curW);
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
        }

        // uniforms occlusion pass
        occlusion_pass.SetTexture("_RadianceTex", PrevCascade);
        occlusion_pass.SetInt("DirectionCount", zeroDirectionCount);
        occlusion_pass.SetInt("W", zeroW);

        Graphics.Blit(OcclusionTexture, destination, occlusion_pass);

        // release textures
        RenderTexture.ReleaseTemporary(PrevCascade);
    }
}
