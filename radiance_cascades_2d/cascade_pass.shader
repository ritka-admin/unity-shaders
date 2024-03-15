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
                // int total_steps = 100;
                float2 start_step = CurCascade == 0 ? pos + dir : pos + (dir * (1 << 3) * (1 << CurCascade - 1));
                float4 cur_step_color = tex2D(_MainTex, start_step);

                // int total_steps = 200 * CurCascade;
                // float2 start_step = pos + (dir * (1 << 2 * (CurCascade - 1)));
                // float2 end_step = pos + (dir * (1 << 2 * CurCascade));
                // float4 cur_step_color = tex2D(_MainTex, start_step);

                // float2 start_step = pos + dir;
                // int total_steps = 400;
                // float4 cur_step_color = tex2D(_MainTex, start_step);

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

            float4 frag (v2f i) : SV_Target
            {
                int angle_idx = floor(i.uv.x * DirectionCount);

                float2 source_tex_coord = float2(
                    // (i.uv.x - float(W) / OutputTexWidth * square_n) * float(DirectionCount),
                    modf(i.uv.x * DirectionCount, angle_idx),
                    i.uv.y
                );
                
                // текущий результат не нужен ни за чем, кроме того, чтобы определить, пересекается ли текущий луч с чем-то...?
                float result = get_result(source_tex_coord, angle_idx);
                
                // если пересеклись или на последнем каскаде -- возвращаем значение
                if (CurCascade == NCascades - 1 || floor(result) == 0.0) {
                    return result;
                }

                result = 0.0;
                int prev_rays = 2;
                // если нет -- забираем значение из предыдущего каскада: выбираем нужные направления и по ним усредняем
                for (int j = 1; j <= prev_rays; ++j) {       // TODO
                    
                    int prev_d = DirectionCount * 2;
                    int prev_w = W / 2;
                    float2 square_coord = float2(
                        source_tex_coord.x / prev_d + prev_w / _PrevCascade_TexelSize.z * (angle_idx + 1) * j,
                        i.uv.y
                    );

                    result += tex2D(_PrevCascade, square_coord).r;

                }

                result /= prev_rays;
                return result;
            }
            
            ENDCG
        }
    }
}
