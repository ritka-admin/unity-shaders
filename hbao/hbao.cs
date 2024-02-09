using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class hbao : MonoBehaviour
{
    [Range(2, 200)]
    public int radius = 20;

    [Range(4, 60)]
    public int rays_num = 10;

    [Range(1, 100)]
    public int ray_steps_num = 20;

    private Material ao_factor_pass;

    void Awake ()
    {
        ao_factor_pass = new Material( Shader.Find("Hidden/ao_factor_pass") );
    }

    void OnPreCull()
	{
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth | DepthTextureMode.DepthNormals;
	}

    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        RenderTexture ao_factor_tex = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.ARGBFloat);
        ao_factor_pass.SetInt("radius", radius);
        ao_factor_pass.SetInt("rays_num", rays_num);
        ao_factor_pass.SetInt("ray_steps_num", ray_steps_num);
        Graphics.Blit(source, destination, ao_factor_pass);
    }
}
