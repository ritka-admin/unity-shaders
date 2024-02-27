Shader "Hidden/occlusion_pass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _CameraDepthTexture_TexelSize;


            bool out_of_frame(float2 pos) {
                return pos.x < 0 || pos.y < 0 || pos.x * _ScreenParams.x/_ScreenParams.y > 1.0 || pos.y * _ScreenParams.y/_ScreenParams.x > 1.0;
            }

            float4 frag (v2f i) : SV_Target
            {
                if ((int) tex2D(_MainTex, i.uv).x == 0 || i.uv.x * _ScreenParams.x / _ScreenParams.y > 1.0) {
                    return float4(0.0, 0.0, 0.0, 1.0);
                }
            
                int rays_num = 360;
            
                float3 light = float3(0.0, 0.0, 0.0);
                float3 light_color = float3(1.0, 1.0, 1.0);
                float cur_angle = 0.0;
                float angle_step = 2 * 3.1415926 / rays_num;

                for (int j = 0; j < rays_num; ++j) {
                    
                    float2 cur_angle_dir = float2(sin(cur_angle), cos(cur_angle)) * _MainTex_TexelSize.xy;
                    float2 cur_step = i.uv + cur_angle_dir;
                    float4 cur_step_color = tex2D(_MainTex, cur_step);
                    
                    int steps = 400;
                    int k = 0;

                    [loop]
                    for (k; k < steps; ++k) {
                        
                        // если врезались во что-то -- break
                        if ((int) cur_step_color.x == 0) // || out_of_frame(cur_step) (if texture wrap_mode == repeat)
                        {
                            break;
                        }
                        
                        cur_step += cur_angle_dir;
                        cur_step_color = tex2D(_MainTex, cur_step);
                    }

                    if (k == steps) { //|| out_of_frame(cur_step) (if texture wrap_mode == repeat)
                        light += light_color;
                    }
                    
                    cur_angle += angle_step;
                }

                light /= rays_num;
                return float4(light.xyz, 1.0);
            }
            
            ENDCG
        }
    }
}
