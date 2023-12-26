Shader "Hidden/gbuffer_pass"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
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
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D_float _MainTex;
            sampler2D_float _CameraDepthNormalsTexture;
            sampler2D_float _CameraDepthTexture;

            float4 frag (float2 uv : TEXCOORD0) : SV_Target
            {
                float depth = tex2D(_CameraDepthTexture, uv).r;
                
                // переводим uv из (0, 1) в clip space
                // uv --- координаты в пикселях
                float4 prev_coord = float4(uv * 2.0 - 1.0, depth, 1.0);

                // переводим из clip space во view space
                float4 camera_position = mul(unity_CameraInvProjection, prev_coord);

                return float4(camera_position.xyz / camera_position.w, 1.0);
            }

            ENDCG
        }
    }
}
