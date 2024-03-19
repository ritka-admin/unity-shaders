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
                
                // exclude the points lying between two WxW squares in _RadianceTex
                float w_half_pixels = _MainTex_TexelSize.z / (float(W * 2));
                float w_half_coordinates = w_half_pixels / _MainTex_TexelSize.z;
                i.uv.x = clamp(i.uv.x, w_half_coordinates, w_half_coordinates * (W * 2 - 1));

                [loop]
                for (int j = 1; j <= DirectionCount; ++j) {

                    float2 square_coord = float2(
                        i.uv.x / DirectionCount + float(W) / _RadianceTex_TexelSize.z * j,
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


// several cascades:

// 1) У каждого каскада есть номер, по номеру определяем кол-во лучей и radiance interval, который этот каскад покрывает
// 2) Заполняем массив для каждого каскада в отдельном проходе
// 3) При заполнении массива мёрджимся с предыдущим каскадом сразу (*)
// 4) Получившуюся текстуру (она будет одна) семплируем



// (*) ----------------------- (*)
// - заполняем каскады от меньшего кол-ва проб к большему
// - при заполнении каскада i: 
//                      - считаем его значение
//                      - находим 4 ближайшие пробы из предыдущего каскада
//                      - интепролируемся между ними
//                      - полученное значение мёрджим с нашим значением (среднее?)