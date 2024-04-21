Shader "Hidden/occlusion_pass_3d"
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
            float SkyIntensity;

            // sampler2D _MainTex;
            sampler2D _RadianceTex;
            sampler2D _CameraDepthNormalsTexture;
            float4 _MainTex_TexelSize;
            float4 _RadianceTex_TexelSize;

            const float pi = 3.1415926;

            float get_dir_result(float2 dir2d, float2 radiance_uv, float3 normal) {
                float result = 0.0;
                float4 sectors_value = tex2D(_RadianceTex, radiance_uv);

                int sectors = 4;
                for (int s = 0; s < sectors; ++s) {
                    float theta = (s + 0.5) / sectors * pi;
                    float3 dir = float3(dir2d * sin(theta), cos(theta));
                    float light = 0.0;

                    if (s == 0) {
                        light = sectors_value.x;
                    } else if (s == 1) {
                        light = sectors_value.y;
                    } else if (s == 2) {
                        light = sectors_value.z;
                    } else if (s == 3) {
                        light = sectors_value.w;
                    }

                    result += max(0.0, dot(normalize(dir), normalize(normal))) * light; // OK
                }

                return result;
            }

            float4 frag (v2f i) : SV_Target
            {   
                float3 normal = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, i.uv));
                float res = 0.0;
                
                float w_half_coordinates = 0.5 / float(_RadianceTex_TexelSize.w);
                i.uv.x = clamp(i.uv.x, w_half_coordinates, 1.0 - w_half_coordinates);
                
                [loop]
                for (int j = 0; j < DirectionCount; ++j) {

                    float2 square_coord = float2(
                        (j + i.uv.x) / DirectionCount,
                        i.uv.y
                    );

                    // if (j == 2) {
                    //     return tex2D(_RadianceTex, square_coord);
                    // }

                    float4 sectors_value = tex2D(_RadianceTex, square_coord);
                    float angle2d = (2 * pi / DirectionCount) * (j + 0.5);
                    float2 dir2d = float2(sin(angle2d), cos(angle2d)) * _MainTex_TexelSize.xy;
                    
                    res += get_dir_result(dir2d, square_coord, normal);
                }
                
                res /= DirectionCount; // OK
                return float4(res, res, res, 1.0);
            }
            ENDCG
        }
    }
}