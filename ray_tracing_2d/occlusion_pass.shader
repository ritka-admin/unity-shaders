Shader "Hidden/occlusion_pass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        SunSize ("SunSize", Range(0, 1.57)) = 0
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

            float SunSize;
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
                
                float3 sky_color = float3(0.5, 0.5, 0.5);
                float3 sun_color = float3(1.0, 1.0, 1.0);
                float2 sun_direction = normalize(-float2(-0.5, -0.5));
                // float2 sun_position = float2(0.4, 0.6);
                // float sun_radius = 0.35;

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
                        
                        // standard approach
                        // light += sun_color;
                        
                        // point lightning
                        // float2 res = clamp(cur_step, sun_position - sun_radius, sun_position + sun_radius);

                        // if (res.x != cur_step.x && res.y != cur_step.y) {
                        //     light += sky_color;
                        // } else {
                        //     light += sun_color;
                        // }
                        
                        // dependance on direction (my)
                        // float coef = dot(normalize(cur_step), sun_direction);
                        // light += lerp(sky_color, sun_color, coef);

                        // dependance on direction (Timur)
                        light += sky_color;

                        float coef = dot(normalize(cur_step), sun_direction);
                        if (coef > SunSize) {
                            light += sun_color;
                        }
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
