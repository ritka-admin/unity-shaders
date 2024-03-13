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
                int total_steps = 400;
                float2 cur_step = pos + dir;
                float4 cur_step_color = tex2D(_MainTex, cur_step);

                int k = 0;

                [loop]
                for (k; k < total_steps; ++k) {
                    
                    if (floor(cur_step_color.x) == 0)
                    {
                        return true;
                    }
                    
                    cur_step += dir;
                    cur_step_color = tex2D(_MainTex, cur_step);
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
                
                return ray_march(cur_angle, source_uv);
            }

            float4 frag (v2f i) : SV_Target
            {
                int angle_idx = floor(i.uv.x * DirectionCount);

                float2 source_tex_coord = float2(
                    // (i.uv.x - float(W) / OutputTexWidth * angle_idx) * float(DirectionCount),
                    modf(i.uv.x * DirectionCount, angle_idx),
                    i.uv.y
                );
                
                // debug
                
                // 1 
                // return float4(source_tex_coord, square_n /float(DirectionCount), 1.0);
                
                // 2
                // return tex2D(_MainTex, source_tex_coord);

                return get_result(source_tex_coord, angle_idx);
            }
            
            ENDCG
        }
    }
}
