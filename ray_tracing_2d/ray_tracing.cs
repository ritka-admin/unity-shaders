using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class ray_tracing : MonoBehaviour
{
    private Texture2D occlusionTexture;
    private Material occlussion_pass;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (occlussion_pass == null) 
        {
            occlussion_pass = new Material( Shader.Find("Hidden/occlusion_pass") );
        }

        // if (occlusionTexture == null) 
        // {
            occlusionTexture = Resources.Load<Texture2D>("occlusion"); // без расширения!
        // }

        Graphics.Blit(occlusionTexture, destination, occlussion_pass);
    }
}