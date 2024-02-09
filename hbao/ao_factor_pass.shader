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
            float4 _CameraDepthTexture_TexelSize;

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

            float tangent(float3 H)
            {
                return H.z / length(H.xy);
            }

            float4 frag (v2f i) : SV_Target
            {
                float pi = 3.1415926;
                float3 our_pos = get_camera_position(i.uv);

                float ao_factor = 0.0;
                float cur_angle = 0.0;
                float angle_step = 2 * 3.1415926 / rays_num;

                for (int j = 0; j < rays_num; ++j) {
                    
                    float ray_max_angle = -pi / 2;
                    float2 cur_angle_dir = float2(sin(cur_angle), cos(cur_angle)) * _CameraDepthTexture_TexelSize.xy * radius;	// radius with dir
                    
                    for (int k = 0; k < ray_steps_num; ++k) {
                        
                        float offset = float(k) / ray_steps_num + 1.0 / radius;
                        float3 sample_pos = get_camera_position(i.uv + cur_angle_dir * offset);
                        float3 horizon_vector = sample_pos - our_pos;

                        float tg = tangent(horizon_vector);
                        float h_angle = atan(tg);

                        ray_max_angle = max(h_angle, ray_max_angle);
                    }
                    
                    // pi/2 - max_angle not to (1 - ao_factor) later
                    ao_factor += (pi - 2 * ray_max_angle) / pi;
                    cur_angle += angle_step;
                }

                ao_factor /= rays_num;

                return float4(ao_factor, ao_factor, ao_factor, 1.0);
            }

            ENDCG
        }
    }
}
