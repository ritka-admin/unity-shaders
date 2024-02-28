using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class ray_tracing : MonoBehaviour
{
    private Texture2D occlusionTexture;
    private Material occlussion_pass;

    [Range(0, 1)]
    public float SkyIntensity = 0;

    [Range(0, 1)]
    public float SunIntensity = 1;
    
    [Range(1, 90)]
    public float SunSize = 20;

    [Range(1, 360)]
    public int RaysNum = 360;

    [Range(-1, 1)]
    public float SunDirectionX = -0.5f;

    [Range(-1, 1)]
    public float SunDirectionY = -0.5f;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (occlussion_pass == null) 
        {
            occlussion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );
        }

        occlusionTexture = Resources.Load<Texture2D>("occlusion"); // без расширения!

        occlussion_pass.SetInt("RaysNum", RaysNum);
        occlussion_pass.SetFloat("SkyIntensity", SkyIntensity);
        occlussion_pass.SetFloat("SunDirectionX", SunDirectionX);
        occlussion_pass.SetFloat("SunDirectionY", SunDirectionY);
        occlussion_pass.SetFloat("SunSize", Mathf.Cos(Mathf.Deg2Rad * SunSize));
        occlussion_pass.SetFloat("SunIntensity", SunIntensity * 360 / SunSize);


        Graphics.Blit(occlusionTexture, destination, occlussion_pass);
    }
}