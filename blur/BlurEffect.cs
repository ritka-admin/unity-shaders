using System.Collections;
using UnityEngine;

[ExecuteInEditMode]
public class BlurEffect : MonoBehaviour
{
    public int pixelRadius;
    private Material firstBlurPass;
    private Material secondBlurPass;
    
    // Creates a private material used to the effect
    void Awake ()
    {
        // Debug.LogError("here");
    }
    
    // Postprocess the image
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        firstBlurPass = new Material( Shader.Find("Unlit/shaderFirstPass") );     // TODO: Hidden/shader
        secondBlurPass = new Material( Shader.Find("Unlit/shaderSecondPass") );

        if (pixelRadius == 0)
        {
            Graphics.Blit(source, destination);
            return;
        }
        
        RenderTexture blurTexture = new RenderTexture(source);
        // RenderTexture blurTexture = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.RGB565);
        firstBlurPass.SetFloat("pixelRadius", pixelRadius);
        Graphics.Blit(source, blurTexture, firstBlurPass);
        
        secondBlurPass.SetFloat("pixelRadius", pixelRadius);
        Graphics.Blit (blurTexture, destination, secondBlurPass);
    }

}
