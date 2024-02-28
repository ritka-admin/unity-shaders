using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class ray_tracing : MonoBehaviour
{
    private Texture2D occlusionTexture;
    private Material occlussion_pass;
    
    [Range(1, 90)]
    public float SunSize = 20;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (occlussion_pass == null) 
        {
            occlussion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );
        }

        occlusionTexture = Resources.Load<Texture2D>("occlusion"); // без расширения!
        occlussion_pass.SetFloat("SunSize", Mathf.Cos(Mathf.Deg2Rad * SunSize));

        Graphics.Blit(occlusionTexture, destination, occlussion_pass);
    }
}