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

            int RaysNum;
            float SunSize;
            float SkyIntensity;
            float SunIntensity;
            float SunDirectionX;
            float SunDirectionY;

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _CameraDepthTexture_TexelSize;
            
            int get_step(int total_steps, float2 cur_angle_dir, float2 uv) {
                float2 cur_step = uv + cur_angle_dir;
                float4 cur_step_color = tex2D(_MainTex, cur_step);

                int k = 0;

                [loop]
                for (k; k < total_steps; ++k) {
                    
                    // если врезались во что-то -- break
                    if (floor(cur_step_color.x) == 0)
                    {
                        break;
                    }
                    
                    cur_step += cur_angle_dir;
                    cur_step_color = tex2D(_MainTex, cur_step);
                }

                return k;
            }

            float ray_march(float cur_angle, float2 uv) {
                float2 sun_direction = -float2(SunDirectionX, SunDirectionY);
                float light = 0.0;

                int steps = 400;
                float2 cur_angle_dir = float2(sin(cur_angle), cos(cur_angle)) * _MainTex_TexelSize.xy;
                int step = get_step(steps, cur_angle_dir, uv);

                if (step == steps) {
                    
                    // standard approach
                    // light += sun_color;
                    
                    // dependance on direction (my)
                    // float coef = dot(normalize(cur_angle_dir), sun_direction);
                    // light += lerp(SkyIntensity, SunIntensity, coef);

                    // dependance on direction (Timur)
                    light += SkyIntensity;

                    float coef = dot(normalize(cur_angle_dir), normalize(sun_direction));
                    if (coef > SunSize) {
                        light += SunIntensity;
                    }
                }

                return light;
            }

            float4 get_result(float2 uv) {
                if (floor(tex2D(_MainTex, uv).x) == 0 || uv.x > 1.0) {
                    return float4(0.0, 0.0, 0.0, 1.0);
                }

                float pi = 3.1415926;
                float light = 0.0;
                float3 light_color = float3(1.0, 1.0, 1.0);
                float cur_angle = 0.0;
                float angle_step = 2 * pi / RaysNum;
                
                [loop]
                for (int j = 0; j < RaysNum; ++j) {
                    light += ray_march(cur_angle, uv);
                    cur_angle += angle_step;
                }

                light /= RaysNum;
                return float4(light, light, light, 1.0);
            }

            float4 frag (v2f i) : SV_Target
            {
                i.uv.x *= _ScreenParams.x/_ScreenParams.y;
                return get_result(i.uv);
            }
            
            ENDCG
        }
    }
}
