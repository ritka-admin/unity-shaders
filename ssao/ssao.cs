using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class ssao : MonoBehaviour
{

    public int n_samples = 20;
    private Material gbuffer_shader;
    private Material ao_factor_pass;

    void Awake ()
    {
        gbuffer_shader = new Material( Shader.Find("Hidden/gbuffer_pass") );
        ao_factor_pass = new Material( Shader.Find("Hidden/ao_factor_pass") );
    }

    void OnPreCull()
	{
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth | DepthTextureMode.DepthNormals;
	}

    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        RenderTexture ao_factor_tex = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBFloat);
        ao_factor_pass.SetInt("n_samples", n_samples);
        Graphics.Blit(source, destination, ao_factor_pass);
    }
}
