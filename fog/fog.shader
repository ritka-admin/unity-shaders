Shader "Hidden/fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        nearDistance ("nearDistance", Range(0,  0.5)) = 0.2
        farDistance ("farDistance", Range(0.5, 1)) = 0.8
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

            uniform float nearDistance;
            uniform float farDistance;
            
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                fixed4 tex_color = tex2D(_MainTex, i.uv);
                fixed4 fog_color = fixed4(0.94, 0.97, 0.96, 0.5);
                // fixed4 fog_color = fixed4(1, 1, 1, 1.0);
                // float depth = tex2D(_CameraDepthTexture, i.uv);
                float nonlinear_depth = tex2D(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(nonlinear_depth);

                if (depth < nearDistance) {
                    col = tex_color;
                    // col = fog_color;
                } else if (depth > farDistance) {
                    col = fog_color;
                    // col = tex_color;
                } else {
                    float coef = (depth - nearDistance) / (farDistance - nearDistance);
                    // float coef = (farDistance - depth) / (farDistance - nearDistance);
                    col = lerp(tex_color, fog_color, coef);
                }

                return col;
                // return float4(depth, depth, depth, 1.0);
            }
            ENDCG
        }
    }
}
