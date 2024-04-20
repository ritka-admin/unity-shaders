Shader "Hidden/cascade_pass_3d"
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
            
            float Thickness;
            //
            int CurCascade;
            int NCascades;
            int BranchFactor;
            int RadiusScaleFactor;
            float CurInnerRadius;
            float CurOuterRadius;
            int DirectionCount;
            float SunSize;
            float SkyIntensity;
            float SunIntensity;
            float3 SunDirection;
            float SunDirectionZ;
            
            sampler2D _MainTex;
            sampler2D _PrevCascade;
            sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;
            float4 _MainTex_TexelSize;
            float4 _PrevCascade_TexelSize;
            
            static const int visibilityBitCount = 32;
            static const int nSectors = 4;
            static const int sectorRays = 8;
            static const float pi = 3.1415926;
            
            bool create_mask(uint start, uint count)
            {
                return ~(~0u << count) << start;
            }

            bool bit_is_set(uint mask, int index)
            {
                return (mask & (1 << index)) != 0;
            }

            float get_sky_light(float3 dir) 
            {
                // float3 sun_dir = float3(SunDirectionX, SunDirectionY, SunDirectionZ);
                // return SkyIntensity + SunIntensity * float(dot(dir, SunDirection) > SunSize);
                return SkyIntensity;        // TODO
            }

            float3 get_camera_position(float2 uv) 
            {
                float depth = tex2D(_CameraDepthTexture, uv).r;
                #if UNITY_REVERSED_Z
                    float z = depth;
                #else
                    float z = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
                #endif

                float4 prev_coord = float4(uv * 2.0 - 1.0, z, 1.0);
                float4 camera_position = mul(unity_CameraInvProjection, prev_coord);
                return camera_position.xyz / camera_position.w;
            }

            float3 get_normal(float2 uv) 
            {
                return DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv));
                // float _depth;
                // float3 normal;

                // float4 depth_normal = tex2D(_CameraDepthNormalsTexture, uv);
                // DecodeDepthNormal(depth_normal, _depth, normal);
                // return normal;
            }

            float4 add_to_sector_component(int sector, float add, float4 result)
            {
                if (sector == 0) {
                    result.x += add;
                } else if (sector == 1) {
                    result.y += add;
                } else if (sector == 2) {
                    result.z += add;
                } else if (sector == 3) {
                    result.w += add;
                }

                return result;
            }

            float4 get_sector_light(int bit_index, float2 dir2d, float3 normal) 
            {
                float4 result = float4(0.0, 0.0, 0.0, 0.0);
                int sector = floor(float(bit_index) / float(visibilityBitCount) * nSectors);

                float theta = (bit_index + 0.5) / visibilityBitCount * pi;
                float3 dir = float3(dir2d * sin(theta), cos(theta));
                float light = get_sky_light(dir) * sin(theta);      // TODO: max(0.0, dot(dir, normal)) *
                // float light = max(0.0, dot(dir, normal)) * get_sky_light(dir) * sin(theta);

                return add_to_sector_component(sector, light, result);
            }

            uint get_visibility_mask(float3 position, float2 uv, float2 dir)
            {
                uint occlusion = 0;
                float2 cur_step = CurCascade == 0 ? uv + dir : uv + dir * CurInnerRadius;
                float2 end_step = uv + dir * CurOuterRadius;
                int total_steps = length(end_step - cur_step) / length(dir);
                
                [loop]
                for (int j = 0; j < total_steps; j++)
                {
                    float3 position1 = get_camera_position(cur_step);			// марш по лучу от объекта
                    float3 position2 = position1 - float3(0.0, 0.0, Thickness); // марш по лучу на thickness дальше объекта
                    float angle1 = acos(normalize(position1 - position).z);		// theta1 
                    float angle2 = acos(normalize(position2 - position).z);		// theta2
                    uint a1 = uint((angle1 / pi) * visibilityBitCount + 0.5);	// находим секцию для theta1
                    uint a2 = uint((angle2 / pi) * visibilityBitCount + 0.5);	// находим секцию для theta2
                    occlusion |= create_mask(a1, a2 - a1);
                    cur_step += dir;
                }

                return ~occlusion;
            }

            float4 get_last_cascade_radiance(float2 uv, float2 dir2d, float3 position, float3 normal)
            {
                float4 result = float4(0.0, 0.0, 0.0, 0.0);
                uint visibilityMask = get_visibility_mask(position, uv, dir2d);

                int kek = 0;
                
                for (int j = 0; j < visibilityBitCount; j++) {
                    if (!bit_is_set(visibilityMask, j)) {   // if sector is occcluded
                        // ++kek;
                        continue;
                    } 
                    
                    ++kek;
                    float4 partial_res = get_sector_light(j, dir2d, normal);
                    result += partial_res;
                }

                // float lol = float(kek) / float(visibilityBitCount);
                // return float4(lol, lol, lol, lol);
                
                return result / sectorRays;
            }

            float4 get_prev_cascade_radiance(float2 uv, float2 dir2d, float3 position, int angle_idx) 
            {
                float4 result = float4(0.0, 0.0, 0.0, 0.0);
                uint visibilityMask = get_visibility_mask(position, uv, dir2d);

                float4 non_occluded_sectors = float4(0.0, 0.0, 0.0, 0.0);

                for (int j = 0; j < visibilityBitCount; ++j) {
                    int sector = float(j) / float(visibilityBitCount) * nSectors;
                    if (bit_is_set(visibilityMask, j)) {    // if sector not occluded
                        non_occluded_sectors = add_to_sector_component(sector, 1, non_occluded_sectors);
                    }
                }

                int prev_resolution = _PrevCascade_TexelSize.w;
                int prev_dir_count = DirectionCount * BranchFactor;

                float w_half_coordinates = 0.5 / float(prev_resolution);
                uv.x = clamp(uv.x, w_half_coordinates, 1.0 - w_half_coordinates);

                [loop]
                for (int j = 0; j < BranchFactor; ++j) {
                    
                    int dir_n = angle_idx * BranchFactor + j;
                    float2 square_coord = float2(
                        (dir_n + uv.x) / prev_dir_count,
                        uv.y
                    );

                    result += tex2D(_PrevCascade, square_coord) * (non_occluded_sectors / float(sectorRays));
                }

                result /= BranchFactor;
                return result;
            }

            float4 get_result(float cur_angle, float2 uv, int angle_idx) 
            {
                float2 dir2d = float2(sin(cur_angle), cos(cur_angle)) * _MainTex_TexelSize.xy;
                float l = length(dir2d);
                // return float4(0, 0, 0, 0);
                // return float4(l, l, l, l);
                float3 position = get_camera_position(uv);
                float3 normal = get_normal(uv);

                if (CurCascade == NCascades - 1) {
                    return get_last_cascade_radiance(uv, dir2d, position, normal);
                }
                
                return get_prev_cascade_radiance(uv, dir2d, position, angle_idx);
            }


            float4 frag (v2f i) : SV_Target
            {
                int angle_idx = floor(i.uv.x * DirectionCount);
                float cur_angle = (2 * pi / DirectionCount) * (angle_idx);

                float2 source_tex_coord = float2(
                    modf(i.uv.x * DirectionCount, angle_idx),
                    i.uv.y
                );
                
                // return tex2D(_MainTex, source_tex_coord);
                return get_result(cur_angle, source_tex_coord, angle_idx);
            }
            
            ENDCG
        }
    }
}