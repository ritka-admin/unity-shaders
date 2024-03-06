Shader "Hidden/occlusion_pass"
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

            sampler2D _MainTex;
            sampler2D _RadianceTex;
            float4 _MainTex_TexelSize;
            float4 _RadianceTex_TexelSize;

            float4 frag (v2f i) : SV_Target
            {
                // float kek = tex2D(_RadianceTex, i.uv);
                // return float4(kek, kek, kek, 1.0);

                // return tex2D(_RadianceTex, i.uv);

                i.uv.x *= _ScreenParams.x/_ScreenParams.y;
                if (floor(tex2D(_MainTex, i.uv).x) == 0 || i.uv.x > 1.0) {
                    return float4(0.0, 0.0, 0.0, 1.0);
                }
                
                // todo: выводить произвольный квадрат
                int square_n = 1;
                float2 square_coord = float2(
                    (i.uv.x - i.uv.x * float(W) / float(_RadianceTex_TexelSize.z) * (DirectionCount - square_n - 1)),
                    i.uv.y
                );

                return tex2D(_RadianceTex, square_coord);

                // float res = 0.0;

                // [loop]
                // for (int j = 1; j <= DirectionCount; ++j) {
                //     float2 radiance_tex_coord = float2(
                //         i.uv.x * j / float(DirectionCount), 
                //         i.uv.y
                //     );
                //     res += tex2D(_RadianceTex, radiance_tex_coord);
                // }

                // res /= DirectionCount;
                // return float4(res, res, res, 1.0);
            }
            ENDCG
        }
    }
}
