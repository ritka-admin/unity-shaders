Shader "Hidden/ao_factor_pass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}   // VS position
        n_samples ("n_samples", Range(8, 128)) = 8
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
            sampler2D _MainTex;
            sampler2D _CameraDepthNormalsTexture;

            // float gen_random(float2 uv) {
            //     return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123)
            // }

            fixed4 frag (v2f i) : SV_Target
            {
                float ao_factor = 0.0f;

                float _depth;
                float3 normal;
                float4 position = tex2D(_MainTex, i.uv);
                float4 depth_normal = tex2D(_CameraDepthNormalsTexture, i.uv);

                DecodeDepthNormal(depth_normal, _depth, normal);
                
                // traverse by x
                for (int j = 0; j < n_samples * 2 + 1; ++j) {
                    float x;
                    float screen_x = i.screenPos.x * _ScreenParams.x;
                    if (screen_x - n_samples + j < 0 || screen_x - n_samples + j > _ScreenParams.x) {
                        x = (screen_x + n_samples - j) / _ScreenParams.x * 2 - 1;
                    } else {
                        x = (screen_x - n_samples + j) / _ScreenParams.x * 2 - 1;
                    }

                    // traverse by y
                    for (int k = 0; k < n_samples * 2 + 1; ++k) {

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
                        float4 occluder = tex2D(_MainTex, neigh);
                        float3 diff = occluder - position;
                        float d = length(diff);
                        ao_factor += max(dot(normal, normalize(diff)), 0.0) * (1.0 / (1.0 + d));
                        // return fixed4(occluder.xyz, 1.0);
                    }
                }
                
                ao_factor /= pow(n_samples * 2 + 1, 2);
                ao_factor = 1 - ao_factor;
                return fixed4(ao_factor, ao_factor, ao_factor, 1.0);
                // return fixed4(normal.x, normal.y, normal.z, 1.0);
                // return fixed4(depth, depth, depth, 1.0);
            }
            ENDCG
        }
    }
}
