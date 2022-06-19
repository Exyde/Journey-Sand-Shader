Shader "Custom/Surface"
{
    Properties
    {
        [Header(Diffuse)]
        [Space(10)]
        _SandColor ("Sand Color", Color) = (1,1,1,1)
        _TerrainColor ("Terrain Color", Color) = (1, 1 ,1 , 1)
        _ShadowColor("Shadow Color", Color) = (1, 1 ,1 , 1)

        [Header(Bump and Normal)]
        [Space (10)]
        _SandTex("Sand Bump Map", 2D) = "white" {}
        _SandStrength("Sand Strength", Range(0.0, 1.0)) = 0.5

        [Header(Rim)]
        [Space(10)]
        _TerrainRimColor("Rim Color", Color) = (1, 1, 1, 1)
        _TerrainRimPower("Rim Specular", Range(0.0, 1.0)) = 0.5
        _TerrainRimStrength("Rim Gloss", Range(0.0, 1.0)) = 0.5

        [Header(Ocean)]
        [Space(10)]
        _OceanSpecularColor("Specular Color", Color) = (1,1,1,1)
        _OceanSpecularPower("Ocean Specular", Range(0.0, 1.0)) = 0.5
        _OceanSpecularStrength("Ocean Gloss", Range(0.0, 1.0)) = 0.5

        [Header(Glitter)]
        [Space(10)]
        _GlitterColor("Glitter Color", Color) = (1,1,1,1)
        _GlitterTex("Glitter Texture", 2D) = "white" {}
        _GlitterThreshold("Glitter Threshold", Range(0.0, 1.0)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        CGPROGRAM
        #pragma surface surf Journey fullforwardshadows

        #pragma target 3.0
        #include "UnityPBSLighting.cginc"

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        inline void LightingJourney_GI(SurfaceOutputStandard s,UnityGIInput data , inout UnityGI gi) {
           LightingStandard_GI(s, data, gi);
        }

        struct Input
        {
            float2 uv_SandTex;
            float2 uv_GlitterTex;

            float3 worldNormal;
            INTERNAL_DATA
        };

        //Reimplementation of slerp( Spherical interpolation ) just by normalizing a lerp.
        float3 nlerp(float3 n1, float3 n2, float t)
        {
            return normalize(lerp(n1, n2, t));
        }

        sampler2D_float _SandTex;
        float _SandStrength;

        float3 SandNormal(float2 uv, float3 N) {
            
            //Get a random vector based on uv
            float3 random = tex2D(_SandTex, uv).rgb;

            //Remapping the direction from [0,1] to [-1, 1]
            float3 S = normalize(random * 2 - 1);

            //Tilt the normal toward S based on Sand Strengh
            float Ns = nlerp(N, S, _SandStrength);

            return Ns;
        }

        float _TerrainRimPower;
        float _TerrainRimStrength;
        float3 _TerrainRimColor;

        float3 RimLighting(float3 N, float3 V) {
            float rim = 1.0 - saturate(dot(N, V)); 
            rim = saturate(pow(rim, _TerrainRimPower) * _TerrainRimStrength);
            rim = max(rim, 0);
            return rim * _TerrainRimColor;
        }

        float _OceanSpecularPower;
        float _OceanSpecularStrength;
        float3 _OceanSpecularColor;

        float3 OceanColor(float3 N, float3 L, float3 V) {
            // Blinn-Phong
            float3 H = normalize(V + L); // Half direction
            float NdotH = max(0, dot(N, H));
            float specular = pow(NdotH, _OceanSpecularPower) * _OceanSpecularStrength;
            return specular * _OceanSpecularColor;
        }

        fixed4 _SandColor;
        float3 _TerrainColor;
        float3 _ShadowColor;

        float3 DiffuseColor(float3 N, float3 L) {
            //Lambert Model but modified
            //Diffuse-Constrat named by JohnEdwards, Tech Artist on journey.
            
            //tweaking the normal a bit
            N.y *= 0.3;

            //Multiply the light intensy by 4 to create more lighthed region and higher contrast.
            float NDotL = saturate(4 * dot(N, L));
            float3 color = lerp(_ShadowColor, _TerrainColor, NDotL);
            return color;
        }

        sampler2D_float _GlitterTex;
        float _GlitterThreshold;
        float3 _GlitterColor;

        float3 GlitterSpecular(float2 uv, float3 N, float3 L, float3 V)
        {
            // Random glitter direction
            float3 G = normalize(tex2D(_GlitterTex, uv).rgb * 2 - 1); // [0,1]->[-1,+1]

            // Light that reflects on the glitter and hits the eye
            float3 R = reflect(L, G);
            float RdotV = max(0, dot(R, V));

            // Only the strong ones (= small RdotV)
            if (RdotV > _GlitterThreshold)
                return 0;

            return (1 - RdotV) * _GlitterColor;
        }

        float4 LightingJourney(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
        {
            float3 L = gi.light.dir;
            float3 N = s.Normal;
            float3 V = viewDir;

            float3 diffuseColor = DiffuseColor(N, L);
            float3 rimColor = RimLighting(N, V);
            float3 oceanColor = OceanColor(N, L, V);
            //float3 glitterColor = GlitterSpecular(IN.uv_GlitterTex.xy, N, L, V);

            float3 specularColor = saturate(max(rimColor, oceanColor));

            float3 color = diffuseColor + specularColor;

            return float4(color, 1);
            return float4(color * s.Albedo, 1);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            o.Albedo = _SandColor;
            o.Alpha = 1;

            float3 N = float3(0, 0, 1);

            N = SandNormal(IN.uv_SandTex.xy, N);       
           //N = WavesNormal(IN.uv_SandTex.xy, N);
             o.Normal = N;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
