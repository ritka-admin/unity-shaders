Shader "Hidden/cascade_pass"
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
            
            int CurCascade;
            int NCascades;
            //
            int W;
            int DirectionCount;
            float SunSize;
            float SkyIntensity;
            float SunIntensity;
            float SunDirectionX;
            float SunDirectionY;
            float OutputTexWidth;
            
            sampler2D _MainTex;
            sampler2D _PrevCascade;
            float4 _MainTex_TexelSize;
            float4 _PrevCascade_TexelSize;

            float get_light(float2 cur_angle_dir)
            {
                float2 sun_direction = -float2(SunDirectionX, SunDirectionY);
                float light = SkyIntensity;

                float coef = dot(normalize(cur_angle_dir), normalize(sun_direction));
                if (coef > SunSize) {
                    light += SunIntensity;
                }
                
                return light;
            }

            bool ray_intersecs_scene(float2 pos, float2 dir) {
                // Промежуток, на котором трекаем луч: ( 2^CurCascade, 2^(CurCascade + 1) ]
                // 1-й каскад -- 8 пикселей вокруг, 2-ый -- 16 и тд
                int total_steps = CurCascade == 0 ? 1 << 3 : 1 << (3 + CurCascade);
                float2 start_step = CurCascade == 0 ? pos + dir : pos + (dir * (1 << 3) * (1 << CurCascade - 1));
                float4 cur_step_color = tex2D(_MainTex, start_step);

                int k = 0;

                [loop]
                for (k; k < total_steps; ++k) {
                    
                    if (floor(cur_step_color.x) == 0)
                    {
                        return true;
                    }
                    
                    start_step += dir;
                    cur_step_color = tex2D(_MainTex, start_step);
                }

                return false;
            }

            float ray_march(float cur_angle, float2 source_uv) 
            {
                float2 cur_angle_dir = float2(sin(cur_angle), cos(cur_angle)) * _MainTex_TexelSize.xy;

                if (ray_intersecs_scene(source_uv, cur_angle_dir)) {
                    return 0.0;
                }

                return get_light(cur_angle_dir);
            }

            float get_result(float2 source_uv, int angle_idx) 
            {
                float pi = 3.1415926;
                float cur_angle = (2 * pi / DirectionCount) * angle_idx;
                // смещение
                cur_angle += cur_angle / 2;
                
                return ray_march(cur_angle, source_uv);
            }

            float merge_with_prev(float2 uv, float2 source_tex_coord, float angle_idx) {
                float result = 0.0;
                int prev_rays = 2;
                int prev_w = W >> 1;
                int prev_d = DirectionCount << 1;

                float w_half_pixels = _MainTex_TexelSize.z / (float(prev_w * 2));
                float w_half_coordinates = w_half_pixels / _MainTex_TexelSize.z;
                source_tex_coord.x = clamp(source_tex_coord.x, w_half_coordinates, w_half_coordinates * (prev_w * 2 - 1));

                for (int j = 1; j <= prev_rays; ++j) {
                    
                    int dir_n = angle_idx * 2 + (j-1);
                    float2 square_coord = float2(
                        source_tex_coord.x / prev_d + prev_w / _PrevCascade_TexelSize.z * dir_n,
                        uv.y
                    );

                    result += tex2D(_PrevCascade, square_coord).r;

                }

                result /= prev_rays;
                return result;
            }

            float frag (v2f i) : SV_Target
            {
                int angle_idx = floor(i.uv.x * DirectionCount);

                float2 source_tex_coord = float2(
                    // (i.uv.x - float(W) / OutputTexWidth * angle_idx) * float(DirectionCount),
                    modf(i.uv.x * DirectionCount, angle_idx),
                    i.uv.y
                );
                
                float result = get_result(source_tex_coord, angle_idx);
                
                // если пересеклись или на последнем каскаде -- возвращаем значение
                if (CurCascade == NCascades - 1 || result == 0.0) {
                    return result;
                }

                return merge_with_prev(i.uv, source_tex_coord, angle_idx);
            }
            
            ENDCG
        }
    }
}
