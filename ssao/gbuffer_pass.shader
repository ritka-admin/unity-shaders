Shader "Hidden/gbuffer_pass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

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

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            fixed4 frag (float2 uv : TEXCOORD0) : SV_Target
            {
                float depth = tex2D(_CameraDepthTexture, uv).r;
                // depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);

                // get coordinates using depth buffer
                fixed4 prev_coord = fixed4(uv * 2.0 - 1.0, depth, 1.0);
                fixed4 camera_position = mul(unity_CameraInvProjection, prev_coord);
                // float kek = -(camera_position.z / camera_position.w) * 0.1;
                // return fixed4(kek, kek, kek, 1.0);
                return fixed4(camera_position.xyz / camera_position.w, 1.0);
            }

            ENDCG
        }
    }
}
