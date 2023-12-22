using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ssao : MonoBehaviour
{

    public int n_samples = 32;
    private Material gbuffer_shader;
    private Material ao_factor_pass;
    private Material final_shader;  

    void Awake ()
    {
        gbuffer_shader = new Material( Shader.Find("Hidden/gbuffer_pass") );
        ao_factor_pass = new Material( Shader.Find("Hidden/ao_factor_pass") );
        final_shader = new Material( Shader.Find("Hidden/ssao_pass") );
    }

    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        // first pass: form gbuffer
        RenderTexture position_tex = new RenderTexture(source);
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
        Graphics.Blit(source, position_tex, gbuffer_shader);
        // Graphics.Blit(source, destination, gbuffer_shader);

        // second pass: form occlussion factor buffer
        RenderTexture ao_factor = new RenderTexture(source);
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
        ao_factor_pass.SetInt("n_samples", n_samples);
        Graphics.Blit(position_tex, destination, ao_factor_pass);

        // final_shader.SetTexture("ao_factor", ao_factor);        // TODO: add in shader
        // Graphics.Blit(source, destination, final_shader);

        // Graphics.Blit(position_tex, destination, ao_factor_pass);
    }
}
