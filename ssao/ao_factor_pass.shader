Shader "Hidden/ao_factor_pass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}   // VS position
        n_samples ("n_samples", Range(1, 40)) = 1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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
                float4 screenPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(v.vertex);
                return o;
            }

            int n_samples;
            sampler2D_float _MainTex;
            sampler2D_float _CameraDepthNormalsTexture;
            sampler2D_float _CameraDepthTexture;
            uniform float4 _MainTex_TexelSize;

            float gen_random(float2 uv) {
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
            }

            float4 get_camera_position(float2 uv) {
                float depth = tex2D(_CameraDepthTexture, uv).r;
                float4 prev_coord = float4(uv * 2.0 - 1.0, depth, 1.0);
                float4 camera_position = mul(unity_CameraInvProjection, prev_coord);
                float4 position = float4(camera_position.xyz / camera_position.w, 1.0);
                return position;
            }

            float4 frag (v2f i) : SV_Target
            {
                float ao_factor = 0.0f;
                float _depth;
                float3 normal;

                float4 depth_normal = tex2D(_CameraDepthNormalsTexture, i.uv);
                DecodeDepthNormal(depth_normal, _depth, normal);

                float4 position = get_camera_position(i.uv);
                // return position;

                // traverse by x
                int diametr = n_samples * 2 + 1;
                for (int j = 0; j < diametr; ++j) {
                    float x;
                    float screen_x = i.screenPos.x * _ScreenParams.x;
                    if (screen_x - n_samples + j < 0 || screen_x - n_samples + j > _ScreenParams.x) {
                        x = (screen_x + n_samples - j) / _ScreenParams.x * 2 - 1;
                    } else {
                        x = (screen_x - n_samples + j) / _ScreenParams.x * 2 - 1;
                    }

                    // traverse by y
                    for (int k = 0; k < diametr; ++k) {

                        if (j == n_samples && k == n_samples) {
                            continue;
                        }

                        float y;
                        float screen_y = i.screenPos.y * _ScreenParams.y;
                        if (screen_y - n_samples + k < 0 || screen_y - n_samples + k > _ScreenParams.y) {
                            y = (screen_y + n_samples - k) / _ScreenParams.y * 2 - 1;
                        } else {
                            y = (screen_y - n_samples + k) / _ScreenParams.y * 2 - 1;
                        }
                        
                        float2 neigh = float2(x, y); 
                        float4 occluder = get_camera_position(neigh);
                        float3 diff = occluder - position;
                        float d = length(diff);
                        ao_factor += max(dot(normal, normalize(diff)) + 0.3f, 0.0f) / (0.5f + d);
                        // ao_factor += occluder.z > position.z ? 1.0 : 0.0;
                    }
                }
                
                ao_factor /= (pow(diametr, 2) - 1) * 0.8;
                // return float4(ao_factor, ao_factor, ao_factor, 1.0);

                ao_factor = 1 - ao_factor;
                float4 color = tex2D(_MainTex, i.uv);
                return color * (1 - ao_factor * 1.5);
            }
            ENDCG
        }
    }
}
