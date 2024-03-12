Shader "Hidden/zero_cascade_pass"
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

            int W;
            int DirectionCount;
            float SunSize;
            float SkyIntensity;
            float SunIntensity;
            float SunDirectionX;
            float SunDirectionY;
            float OutputTexWidth;
            
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            
            int get_step(int total_steps, float2 cur_angle_dir, float2 source_uv) 
            {
                float2 cur_step = source_uv + cur_angle_dir;
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

            float ray_march(float cur_angle, float2 source_uv) 
            {
                float2 sun_direction = -float2(SunDirectionX, SunDirectionY);
                float light = 0.0;

                int steps = 400;
                float2 cur_angle_dir = float2(sin(cur_angle), cos(cur_angle)) * _MainTex_TexelSize.xy;
                int step = get_step(steps, cur_angle_dir, source_uv);

                if (step == steps) {
                    
                    // standard approach
                    // light += SunIntensity;

                    // dependance on direction
                    light += SkyIntensity;

                    float coef = dot(normalize(cur_angle_dir), normalize(sun_direction));
                    if (coef > SunSize) {
                        light += SunIntensity;
                    }
                }

                return light;
            }

            float get_result(float2 uv, float2 source_uv) 
            {
                float pi = 3.1415926;

                float angle_idx = floor(uv.x * DirectionCount);
                float cur_angle = (2 * pi / DirectionCount) * angle_idx;
                
                return ray_march(cur_angle, source_uv);
            }

            float4 frag (v2f i) : SV_Target
            {
                int square_n = floor(i.uv.x * DirectionCount);

                float2 source_tex_coord = float2(
                    // (i.uv.x - float(W) / OutputTexWidth * square_n) * float(DirectionCount),
                    modf(i.uv.x * DirectionCount, square_n),
                    i.uv.y
                );
                
                // debug
                
                // 1 
                // return float4(source_tex_coord, square_n /float(DirectionCount), 1.0);
                
                // 2
                // return tex2D(_MainTex, source_tex_coord);

                return get_result(i.uv, source_tex_coord);
            }
            
            ENDCG
        }
    }
}
