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

            int DirectionCount;
            float contrast;

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
                
                // exclude the points lying between two WxW squares in _RadianceTex
                float w_half_coordinates = 0.5 / float(_RadianceTex_TexelSize.w);
                i.uv.x = clamp(i.uv.x, w_half_coordinates, 1.0 - w_half_coordinates);

                [loop]
                for (int j = 0; j < DirectionCount; ++j) {

                    float2 square_coord = float2(
                        (j + i.uv.x) / DirectionCount,
                        i.uv.y
                    );

                    res += tex2D(_RadianceTex, square_coord).r;
                }
                
                res /= DirectionCount;
                return float4(res, res, res, 1.0);

                // float4 color = float4(res, res, res, 1.0);
                // return pow(color, 5.0) * 50.0;
                // return saturate(lerp(float4(0.5, 0.5, 0.5, 1), color, contrast));
            }
            ENDCG
        }
    }
}