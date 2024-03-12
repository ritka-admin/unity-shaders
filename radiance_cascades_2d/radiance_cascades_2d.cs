using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class radiance_cascades_2d : MonoBehaviour
{
    private Material zero_cascade_pass;
    private Material occlusion_pass;
    private Texture2D OcclusionTexture;

    [Range(0, 256)]
    public int W = 256;

    [Range(4, 100)]
    public int directionCount = 4;

    [Range(1, 90)]
    public float sunSize = 20;

    [Range(0, 1)]
    public float skyIntensity = 0;

    [Range(0, 1)]
    public float sunIntensity = 1;

    [Range(-1, 1)]
    public float sunDirectionX = -0.5f;

    [Range(-1, 1)]
    public float sunDirectionY = -0.5f;


    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // shaders
        zero_cascade_pass = new Material( Shader.Find("Hidden/zero_cascade_pass") );
        occlusion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );

        // textures
        OcclusionTexture = Resources.Load<Texture2D>("occlusion");

        RenderTexture RadianceTexture = RenderTexture.GetTemporary(W * directionCount, W, 0, RenderTextureFormat.RFloat);
        RadianceTexture.filterMode = FilterMode.Bilinear;
        RadianceTexture.wrapMode = TextureWrapMode.Clamp;

        // uniforms first pass
        zero_cascade_pass.SetInt("W", W);
        zero_cascade_pass.SetFloat("OutputTexWidth", RadianceTexture.width);
        zero_cascade_pass.SetInt("DirectionCount", directionCount);
        zero_cascade_pass.SetFloat("SkyIntensity", skyIntensity);
        zero_cascade_pass.SetFloat("SunDirectionX", sunDirectionX);
        zero_cascade_pass.SetFloat("SunDirectionY", sunDirectionY);
        zero_cascade_pass.SetFloat("SunSize", Mathf.Cos(Mathf.Deg2Rad * sunSize));
        zero_cascade_pass.SetFloat("SunIntensity", sunIntensity * 360 / sunSize);

        Graphics.Blit(OcclusionTexture, RadianceTexture, zero_cascade_pass);

        // uniforms second pass
        occlusion_pass.SetTexture("_RadianceTex", RadianceTexture);
        occlusion_pass.SetInt("DirectionCount", directionCount);
        occlusion_pass.SetInt("W", W);

        Graphics.Blit(OcclusionTexture, destination, occlusion_pass);

        // release textures
        RenderTexture.ReleaseTemporary(RadianceTexture);
    }
}
