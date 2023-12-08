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
        // Cull Off ZWrite Off ZTest Always

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

            int n_samples;
            sampler2D _MainTex;
            sampler2D _CameraDepthNormalsTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 factor_vector;
                float ao_factor = 0.0f;

                float depth;
                float3 normal;
                float4 position = tex2D(_MainTex, i.uv);
                float4 depth_normal_texture = tex2D(_CameraDepthNormalsTexture, i.uv);

                DecodeDepthNormal(depth_normal_texture, depth, normal);
                depth = LinearEyeDepth(depth) / 100;        // TODO: how to identify normal scale
                
                for (int j = 0; j < n_samples; ++j) {
                    int mul = pow(-1, j);
                    // float kek_x = i.uv.x + (float) j / n_samples * mul;
                    // float kek_y = i.uv.y + (float) j / n_samples * mul;

                    // float2 coords = float2(kek_x, kek_y);
                    float2 coords = float2(i.uv.x + j / 100 * mul, i.uv.y + j / 100 * mul);
                    float4 occluder = tex2D(_MainTex, coords);
                    float4 diff = occluder - position;
                    float d = length(diff);
                    ao_factor += max(dot(normal, normalize(diff)), 0.0) * 1 / (1 + d);
                }
                
                ao_factor /= n_samples;
                return fixed4(ao_factor, ao_factor, ao_factor, 1.0);
                // return fixed4(normal.x, normal.y, normal.z, 1.0);
            }
            ENDCG
        }
    }
}
