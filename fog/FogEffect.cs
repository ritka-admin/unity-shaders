using System.Collections;
using UnityEngine;

[ExecuteInEditMode]
public class FogEffect : MonoBehaviour
{
    public float nearDistance = 0.2F;
    public float farDistance = 0.8F;
    private Material fogShader;
    
    // Creates a private material used to the effect
    void Awake ()
    {
        fogShader = new Material( Shader.Find("Hidden/fog") );
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
    }
    
    // Postprocess the image
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        fogShader.SetFloat("nearDistance", nearDistance);
        fogShader.SetFloat("farDistance", farDistance);
        Graphics.Blit(source, destination, fogShader);
    }

}
