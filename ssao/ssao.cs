using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class ssao : MonoBehaviour
{

    public int n_samples = 20;
    private Material gbuffer_shader;
    private Material ao_factor_pass;
    private Material final_shader;  

    void Awake ()
    {
        gbuffer_shader = new Material( Shader.Find("Hidden/gbuffer_pass") );
        ao_factor_pass = new Material( Shader.Find("Hidden/ao_factor_pass") );
        final_shader = new Material( Shader.Find("Hidden/ssao_pass") );
    }

    void OnPreCull()
	{
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth | DepthTextureMode.DepthNormals;
	}

    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        // first pass: form gbuffer
        RenderTexture position_tex = new RenderTexture(source);
        // RenderTexture position_tex = RenderTexture.GetTemporary(Screen.width, Screen.height, 32);
        // Graphics.Blit(source, position_tex, gbuffer_shader);
        // Graphics.Blit(source, destination, gbuffer_shader);

        // second pass: form occlussion factor buffer
        // RenderTexture ao_factor_tex = RenderTexture.GetTemporary(Screen.width, Screen.height, 32);
        RenderTexture ao_factor_tex = new RenderTexture(source);
        ao_factor_pass.SetInt("n_samples", n_samples);
        Graphics.Blit(source, destination, ao_factor_pass);
        // Graphics.Blit(ao_factor_tex, destination);

        // final_shader.SetTexture("ao_factor", ao_factor);        // TODO: add in shader
        // Graphics.Blit(source, destination, final_shader);
        // Graphics.Blit(ao_factor, destination);

        // Graphics.Blit(position_tex, destination, ao_factor_pass);
    }
}
