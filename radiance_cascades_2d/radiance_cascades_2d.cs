using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class radiance_cascades_2d : MonoBehaviour
{
    private Material zero_cascade_pass;
    private Material occlusion_pass;
    private Texture2D occlusionTexture;

    [Range(128, 512)]
    public int W = 256;

    [Range(4, 60)]
    public int directionCount = 4;

    [Range(1, 90)]
    public float SunSize = 20;

    [Range(0, 1)]
    public float SkyIntensity = 0;

    [Range(0, 1)]
    public float SunIntensity = 1;

    [Range(-1, 1)]
    public float SunDirectionX = -0.5f;

    [Range(-1, 1)]
    public float SunDirectionY = -0.5f;


    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // shaders
        zero_cascade_pass = new Material( Shader.Find("Hidden/zero_cascade_pass") );
        occlusion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );

        // textures
        occlusionTexture = Resources.Load<Texture2D>("occlusion");

        RenderTexture radianceTexture = RenderTexture.GetTemporary(W * directionCount, W, 0, RenderTextureFormat.R16);
        radianceTexture.filterMode = FilterMode.Bilinear;

        RenderTexture helperTexture = new RenderTexture(radianceTexture);

        // uniforms first pass
        zero_cascade_pass.SetTexture("_Source", occlusionTexture);
        zero_cascade_pass.SetInt("W", W);
        zero_cascade_pass.SetInt("DirectionCount", directionCount);
        zero_cascade_pass.SetFloat("SkyIntensity", SkyIntensity);
        zero_cascade_pass.SetFloat("SunDirectionX", SunDirectionX);
        zero_cascade_pass.SetFloat("SunDirectionY", SunDirectionY);
        zero_cascade_pass.SetFloat("SunSize", Mathf.Cos(Mathf.Deg2Rad * SunSize));
        zero_cascade_pass.SetFloat("SunIntensity", SunIntensity * 360 / SunSize);

        Graphics.Blit(helperTexture, radianceTexture, zero_cascade_pass);

        // uniforms second pass
        occlusion_pass.SetTexture("_RadianceTex", radianceTexture);
        occlusion_pass.SetInt("DirectionCount", directionCount);
        occlusion_pass.SetInt("W", W);

        Graphics.Blit(occlusionTexture, destination, occlusion_pass);
    }
}
