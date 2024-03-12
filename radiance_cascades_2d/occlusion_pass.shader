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
                i.uv.x *= _ScreenParams.x/_ScreenParams.y;
                if (floor(tex2D(_MainTex, i.uv).x) == 0 || i.uv.x > 1.0) {
                    return float4(0.0, 0.0, 0.0, 1.0);
                }

                float res = 0.0;

                float half_pixels = _MainTex_TexelSize.z / (float(W * 2));
                float half_coordinates = half_pixels / _MainTex_TexelSize.z;

                i.uv.x = clamp(i.uv.x, half_coordinates, half_coordinates * (W * 2 - 1));

                [loop]
                for (int j = 1; j <= DirectionCount; ++j) {

                    float rad_coord_x = i.uv.x / DirectionCount + float(W) / _RadianceTex_TexelSize.z * j;

                    float2 square_coord = float2(
                        // i.uv.x / DirectionCount + float(W) / _RadianceTex_TexelSize.z * j,
                        rad_coord_x,
                        i.uv.y
                    );

                    res += tex2D(_RadianceTex, square_coord).r;
                }

                res /= DirectionCount;
                return float4(res, res, res, 1.0);
            }
            ENDCG
        }
    }
}
