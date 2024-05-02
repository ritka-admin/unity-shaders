using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ExecuteAlways]
[ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class radiance_cascades_3d : MonoBehaviour
{
    private Material cascade_pass;
    private Material occlusion_pass;
    private Texture2D OcclusionTexture;

    [Range(1, 512)]
    public int zeroResolution = 256;

    [Range(1, 64)]
    public int zeroDirectionCount = 4;

    [Range(4, 1000)]
    public int zeroIntervalPixels = 8;

    [Range(2, 4)]
    public int radiusScaleFactor = 2;

    [Range(2, 4)]
    public int branchFactor = 2;

    [Range(1, 9)]
    public int nCascades = 1;

    [Range(0, 3)]
    public float skyIntensity = 0;

    [Range(1, 90)]
    public float sunSize = 20;

    [Range(0, 1)]
    public float sunIntensity = 1;

    [Range(0, 360)]
    public float sunAngle = 0;

    [Range(0.1f, 10f)]
	public float thickness = 1.0f;

    [Range(-30.0f, 90.0f)]
	public float sunHeight = 45.0f;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth|DepthTextureMode.DepthNormals;

        cascade_pass = new Material( Shader.Find("Hidden/cascade_pass_3d") );
        occlusion_pass = new Material( Shader.Find("Hidden/occlusion_pass_3d") );

        // fill and merge all cascades
        RenderTexture PrevCascade = null;

        // first prevs correspond with the last
        int prevCascadeResolution = zeroResolution >> nCascades - 1;
        int prevCascadeDirCount = (int) Mathf.Pow(branchFactor, nCascades - 1) * zeroDirectionCount;
        float prevCascadeInnerRadius = Mathf.Pow(radiusScaleFactor, nCascades - 2) * zeroIntervalPixels;
        float prevCascadeOuterRadius = Mathf.Pow(radiusScaleFactor, nCascades - 1) * zeroIntervalPixels;

        for (int i = nCascades - 1; i >= 0; --i) 
        {
            // int curR = i == nCascades - 1 ? prevCascadeResolution : prevCascadeResolution * 2;
            int curR = source.width;
            int curD = i == nCascades - 1 ? prevCascadeDirCount : prevCascadeDirCount / branchFactor;
            float curInnerRadius = i == nCascades - 1 ? prevCascadeInnerRadius : prevCascadeInnerRadius / radiusScaleFactor;
            float curOuterRadius = i == nCascades - 1 ? prevCascadeOuterRadius : prevCascadeInnerRadius;

            // Debug.Log(i + ", curR: " + curR + ", curD: " + curD);
            // Debug.Log(i + ", curInner: " + curInnerRadius + ", curOuter: " + curOuterRadius);

            RenderTexture RadianceTexture = RenderTexture.GetTemporary(curR * curD, curR, 0, RenderTextureFormat.ARGBFloat);
            RadianceTexture.filterMode = FilterMode.Bilinear;
            RadianceTexture.wrapMode = TextureWrapMode.Clamp;

            cascade_pass.SetTexture("_PrevCascade", PrevCascade);
            cascade_pass.SetInt("PrevCascadeDirCount", prevCascadeDirCount);
            cascade_pass.SetInt("PrevCascadeResolution", prevCascadeResolution);
            cascade_pass.SetInt("NCascades", nCascades);
            cascade_pass.SetInt("BranchFactor", branchFactor);
            cascade_pass.SetInt("RadiusScaleFactor", radiusScaleFactor);
            cascade_pass.SetFloat("CurInnerRadius", curInnerRadius);
            cascade_pass.SetFloat("CurOuterRadius", curOuterRadius);
            cascade_pass.SetInt("CurCascade", i);
            cascade_pass.SetInt("DirectionCount", curD);
            cascade_pass.SetFloat("SkyIntensity", skyIntensity);
            cascade_pass.SetFloat("Thickness", thickness);
            cascade_pass.SetVector("SunDirection", GetSunDirection());
            cascade_pass.SetFloat("SunSize", Mathf.Cos(Mathf.Deg2Rad * sunSize));
            cascade_pass.SetFloat("SunIntensity", sunIntensity / GetSunArea());

            Graphics.Blit(source, RadianceTexture, cascade_pass);
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
        occlusion_pass.SetFloat("SkyIntensity", skyIntensity);

        Graphics.Blit(source, destination, occlusion_pass);

        // release textures
        RenderTexture.ReleaseTemporary(PrevCascade);
    }

    private Vector3 GetSunDirection()
	{
		float phi = Mathf.Deg2Rad * sunAngle;
		float theta = Mathf.Deg2Rad * (90 - sunHeight);
		Vector3 direction = new Vector3(
			Mathf.Sin(theta) * Mathf.Cos(phi),
			Mathf.Cos(theta),
			Mathf.Sin(theta) * Mathf.Sin(phi)
		);
		direction = GetComponent<Camera>().worldToCameraMatrix.MultiplyVector(direction);
		return new Vector3(direction.x, direction.y, direction.z);
	}

    private float GetSunArea()
	{
		return (1.0f - Mathf.Cos(Mathf.Deg2Rad * sunSize));
	}
}
