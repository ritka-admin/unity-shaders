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
            
            int ZeroIntervalPixels;
            int CurCascade;
            int NCascades;
            int BranchFactor;
            int RadiusScaleFactor;
            float CurInnerRadius;
            float CurOuterRadius;
            //
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

            bool ray_intersecs_scene(float2 pos, float2 dir) 
            {
                // int cross_steps = 2 * CurCascade;
                int cross_steps = 0;
                float2 start_step = CurCascade == 0 ? pos + dir : pos + dir * (CurInnerRadius - cross_steps);
                float2 end_step = pos + dir * CurOuterRadius;
                int total_steps = length(end_step - start_step) / length(dir);

                float4 cur_step_color = tex2D(_MainTex, start_step);

                int k = 0;

                [loop]
                for (k; k < total_steps; ++k)
                {
                    
                    if (floor(cur_step_color.x) == 0)
                    {
                        return true;
                    }
                    
                    start_step += dir;
                    cur_step_color = tex2D(_MainTex, start_step);
                }

                return false;
            }

            float get_prev_cascade_radiance(float2 position, float angle_idx) 
            {
                float result = 0.0;
                int prev_resolution = _PrevCascade_TexelSize.w;
                int prev_dir_count = DirectionCount * BranchFactor;

                float w_half_coordinates = 0.5 / float(prev_resolution);
                position.x = clamp(position.x, w_half_coordinates, 1.0 - w_half_coordinates);
                
                [loop]
                for (int j = 0; j < BranchFactor; ++j) {
                    
                    int dir_n = angle_idx * BranchFactor + j;
                    float2 square_coord = float2(
                        (dir_n + position.x) / prev_dir_count,
                        position.y
                    );

                    result += tex2D(_PrevCascade, square_coord).r;
                }

                result /= BranchFactor;
                return result;
            }

            float ray_march(float cur_angle, float2 position, int angle_idx) 
            {
                float2 cur_angle_dir = float2(cos(cur_angle), sin(cur_angle)) * _MainTex_TexelSize.xy;

                if (ray_intersecs_scene(position, cur_angle_dir)) {
                    return 0.0;
                }
                
                if (CurCascade == NCascades - 1) {
                    return get_light(cur_angle_dir);
                }

                return get_prev_cascade_radiance(position, angle_idx);
            }

            float get_result(float2 position, int angle_idx) 
            {
                float pi = 3.1415926;
                float cur_angle = (2 * pi / DirectionCount) * (angle_idx + 0.5);  // angle_idx + shift
                return ray_march(cur_angle, position, angle_idx);
            }


            float frag (v2f i) : SV_Target
            {
                int angle_idx = floor(i.uv.x * DirectionCount);

                float2 source_tex_coord = float2(
                    modf(i.uv.x * DirectionCount, angle_idx),
                    i.uv.y
                );
                
                return get_result(source_tex_coord, angle_idx);
            }
            
            ENDCG
        }
    }
}