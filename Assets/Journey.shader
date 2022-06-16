Shader "Custom/Surface"
{
    Properties
    {
        _SandColor ("Sand Color", Color) = (1,1,1,1)
        _TerrainColor ("Terrain Color", Color) = (1, 1 ,1 , 1)
        _ShadowColor("Shadow Color", Color) = (1, 1 ,1 , 1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0


        inline void  LightingJourney_GI(SurfaceOutputStandard s,UnityGIInput data ,inout UnityGI gi) {
            LightingStandard_GI(s, data, gi);
        }


        struct Input
        {
            float2 uv_MainTex;
        };

        fixed4 _SandColor;
        float3 _TerrainColor;
        float3 _ShadowColor;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

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

        float4 LightingJourney(SurfaceOutputStandard  s, fixed3 viewDir, UnityGI gi)
        {
            float3 L = gi.light.dir;
            float3 N = s.Normal;

            float3 diffuseColor = DiffuseColor(N, L);

            return float4(diffuseColor, 1);
        }

        //void vert(inout appdata_full v) {

        //}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            o.Albedo = _SandColor;
            o.Alpha = 1;

            float3 N = float3(0, 0, 1);
            //N = RipplesNormal(N);
            //N = SandNormal(N);
            o.Normal = N;

        }
        ENDCG
    }
    FallBack "Diffuse"
}
