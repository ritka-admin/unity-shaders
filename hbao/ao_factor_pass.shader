Shader "Hidden/ao_factor_pass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        radius ("radius", Range(2, 200)) = 2
        rays_num ("rays_num", Range(10, 60)) = 10
        ray_steps_num ("ray_steps_num", Range(1, 100)) = 1
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

            sampler2D_float _MainTex;
            sampler2D_float _CameraDepthNormalsTexture;
            sampler2D_float _CameraDepthTexture;

            // uniform float _Constant_PI;
            uniform int radius;
            uniform int rays_num;
            uniform int ray_steps_num;

            float3 get_camera_position(float2 uv) {
                float depth = tex2D(_CameraDepthTexture, uv).r;
                #if UNITY_REVERSED_Z
                    float z = 1 - depth;
                #else
                    float z = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
                #endif

                float4 prev_coord = float4(uv * 2.0 - 1.0, z, 1.0);
                float4 camera_position = mul(unity_CameraInvProjection, prev_coord);
                return camera_position.xyz / camera_position.w;
            }

            float tangent(float3 P)
            {
                return P.z / length(P.xy);
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 our_pos = get_camera_position(i.uv);

                float angle_step = 2 * 3.1415926 / rays_num;
                float march_step_pixels = floor(radius / (float) ray_steps_num + 0.5);
                float2 march_step = float2(march_step_pixels / (float) _ScreenParams.x, march_step_pixels / (float) _ScreenParams.y);

                float ao_factor = 0.0;
                float cur_angle = 0.0; 

                for (int j = 0; j < rays_num; ++j) {
                    
                    float x = cos(cur_angle);
                    float y = sin(cur_angle);
                    float2 cur_angle_dir = float2(x, y);
                    float2 ray_step = cur_angle_dir * march_step; 
                    
                    float ray_max_angle = 0.0;
                    float2 ray_cur_value = ray_step;
                    for (int k = 0; k < ray_steps_num; ++k) {

                        float3 sample_pos = get_camera_position(i.uv + ray_cur_value);
                        float3 horizon_vector = sample_pos - our_pos;
                        float tg = tangent(horizon_vector);
                        float h_angle = atan(tg);

                        if (h_angle > ray_max_angle) {
                            ray_max_angle = h_angle;
                        }

                        ray_cur_value += ray_step;
                    }
                    
                    ao_factor += ray_max_angle / (3.1415926 / 2);
                    cur_angle += angle_step;
                }

                ao_factor /= rays_num;
                ao_factor = 1 - ao_factor;

                return float4(ao_factor, ao_factor, ao_factor, 1.0);
            }

            ENDCG
        }
    }
}
