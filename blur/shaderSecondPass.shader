Shader "Unlit/shaderSecondPass"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        pixelRadius ("pixelRadius", Range(0, 100)) = 0
    }

    SubShader
    {
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

            uniform sampler2D _MainTex;
            uniform int pixelRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 tex = i.uv;
                float4 screenCoord = i.screenPos;

                int d = pixelRadius * 2 + 1;
                for (int j = 0; j < d; ++j) {

                    if (j == pixelRadius) {
                        continue;
                    }
                    
                    float y;
                    float screen = screenCoord.y * _ScreenParams.y;
                    if (screen - pixelRadius + j < 0 || screen - pixelRadius + j > _ScreenParams.y) {
                        y = (screen + pixelRadius - j) / _ScreenParams.y * 2 - 1;
                    } else {
                        y = (screen - pixelRadius + j) / _ScreenParams.y * 2 - 1;
                    }

                    float2 tmp = float2(tex.x, y);
                    col += tex2D(_MainTex, tmp);
                }

                col /= d;
                return col;
            }

            ENDCG
        }
    }
}
