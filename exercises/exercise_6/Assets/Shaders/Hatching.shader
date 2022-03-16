Shader "CG2022/Hatching"
{
    Properties
    {
        _Albedo("Albedo", Color) = (1,1,1,1)
        _AlbedoTexture("Albedo Texture", 2D) = "white" {}
        _Reflectance("Reflectance (Ambient, Diffuse, Specular)", Vector) = (1, 1, 1, 0)
        _SpecularExponent("Specular Exponent", Float) = 100.0
        _Hatch0Texture("Hatching0", 2D) = "white" {}
        _Hatch1Texture("Hatching1", 2D) = "white" {}
        _Hatch2Texture("Hatching2", 2D) = "white" {}
        _Hatch3Texture("Hatching3", 2D) = "white" {}
        _Hatch4Texture("Hatching4", 2D) = "white" {}
        _Hatch5Texture("Hatching5", 2D) = "white" {}

        // TODO exercise 6 - Add the required properties here
    }

        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        GLSLINCLUDE
        #include "UnityCG.glslinc"
        #include "ITUCG.glslinc"

        uniform vec4 _Albedo;
        uniform sampler2D _AlbedoTexture;
        uniform vec4 _AlbedoTexture_ST;
        uniform vec4 _Reflectance;
        uniform float _SpecularExponent;

        // TODO exercise 6 - Add the required uniforms here
        uniform sampler2D _Hatch0Texture;
        uniform sampler2D _Hatch1Texture;
        uniform sampler2D _Hatch2Texture;
        uniform sampler2D _Hatch3Texture;
        uniform sampler2D _Hatch4Texture;
        uniform sampler2D _Hatch5Texture;

        uniform vec4 _Hatch0Texture_ST;


        // TODO exercise 6 - Compute the hatching intensity here
        float ComputeHatching(vec3 lighting, vec2 texCoords)
        {
            int levels = 7;

            // TODO exercise 6.3 - Compute the lighting intensity from the lighting color luminance
            float intensity = GetColorLuminance(lighting);

            // TODO exercise 6.3 - Clamp the intensity value between 0 and 1
            intensity = clamp(intensity, 0, 1);

            // TODO exercise 6.3 - Multiply the intensity by the number of levels. This time the number of levels is fixed, 7, given by the number of textures + 1
            intensity = intensity * (levels );

            vec4 tex1;
            vec4 tex2;

            float intensityRange = floor(intensity);

            if (intensityRange == 0)
            {
                tex1 = texture(_Hatch5Texture, texCoords);
                tex2 = vec4(0);
            }
            else if (intensityRange == 1)
            {
                tex1 = texture(_Hatch4Texture, texCoords);
                tex2 = texture(_Hatch5Texture, texCoords);
            }
            else if (intensityRange == 2)
            {
                tex1 = texture(_Hatch3Texture, texCoords);
                tex2 = texture(_Hatch4Texture, texCoords);
            }
            else if (intensityRange == 3)
            {

                tex1 = texture(_Hatch2Texture, texCoords);
                tex2 = texture(_Hatch3Texture, texCoords);
            }
            else if (intensityRange == 4)
            {
                tex1 = texture(_Hatch1Texture, texCoords);
                tex2 = texture(_Hatch2Texture, texCoords);
            }
            else if (intensityRange == 5)
            {
                tex1 = texture(_Hatch0Texture, texCoords);
                tex2 = texture(_Hatch1Texture, texCoords);
            }
            else if (intensityRange == 6)
            {
                tex1 = vec4(1);
                tex2 = texture(_Hatch0Texture, texCoords);
            }
            else 
            {
                tex1 = vec4(1);
                tex2 = vec4(1);
            }

            float ratio = 1 - (intensity - intensityRange);
            
            float mix = mix(tex1, tex2, ratio).r;
            return mix;
        }
        ENDGLSL

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            GLSLPROGRAM

            struct vertexToFragment
            {
                vec3 worldPos;
                vec3 normal;
                vec4 texCoords;
            };

            #ifdef VERTEX
            out vertexToFragment v2f;

            void main()
            {
                v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
                v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;
                v2f.texCoords.xy = TransformTexCoords(gl_MultiTexCoord0.xy, _AlbedoTexture_ST);

                // TODO exercise 6.3 - Transform hatching texture coordinates and pass to the fragment
                v2f.texCoords.zw = TransformTexCoords(gl_MultiTexCoord0.xy, _Hatch0Texture_ST);

                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            in vertexToFragment v2f;

            void main()
            {
                vec3 lightDir = GetWorldSpaceLightDir(v2f.worldPos);
                vec3 viewDir = GetWorldSpaceViewDir(v2f.worldPos);

                vec3 normal = normalize(v2f.normal);

                //vec3 albedo = texture(_Hatch5Texture, v2f.texCoords.xy).xyz;
                vec3 albedo = texture(_AlbedoTexture, v2f.texCoords.xy).rgb;
                albedo *= _Albedo.rgb;

                // Like in the cel-shading exercise, we replace the albedo here with 1.0f
                vec3 lighting = BlinnPhongLighting(lightDir, viewDir, normal, vec3(1.0f), vec3(1.0f), _Reflectance.x, _Reflectance.y, _Reflectance.z, _SpecularExponent);

                float hatch = ComputeHatching(lighting, v2f.texCoords.zw);

                // Like in the cel-shading exercise, we multiply by the albedo and the light color at the end
                gl_FragColor = vec4(hatch * albedo * _LightColor0.rgb, 1.0f);
            }
            #endif // FRAGMENT

            ENDGLSL
        }

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardAdd" }

            ZWrite Off
            Blend One One

            GLSLPROGRAM

            struct vertexToFragment
            {
                vec3 worldPos;
                vec3 normal;
                vec4 texCoords;
            };

            #ifdef VERTEX
            out vertexToFragment v2f;

            void main()
            {
                v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
                v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;
                v2f.texCoords.xy = TransformTexCoords(gl_MultiTexCoord0.xy, _AlbedoTexture_ST);

                // TODO exercise 6.3 - Transform hatching texture coordinates and pass to the fragment
                v2f.texCoords.zw = TransformTexCoords(gl_MultiTexCoord0.xy, _HatchTexture_ST);

                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            in vertexToFragment v2f;

            void main()
            {
                vec3 lightDir = GetWorldSpaceLightDir(v2f.worldPos);
                vec3 viewDir = GetWorldSpaceViewDir(v2f.worldPos);

                vec3 normal = normalize(v2f.normal);

                //vec3 albedo = texture(_Hatch5Texture, v2f.texCoords.xy).xyz;
                vec3 albedo = texture(_AlbedoTexture, v2f.texCoords.xy).rgb;
                albedo *= _Albedo.rgb;

                // Like in the cel-shading exercise, we replace the albedo here with 1.0f
                vec3 lighting = BlinnPhongLighting(lightDir, viewDir, normal, vec3(1.0f), vec3(1.0f), _Reflectance.x, _Reflectance.y, _Reflectance.z, _SpecularExponent);

                float hatch = ComputeHatching(lighting, v2f.texCoords.zw);

                // Like in the cel-shading exercise, we multiply by the albedo and the light color at the end
                gl_FragColor = vec4(hatch * albedo * _LightColor0.rgb, 1.0f);
            }
            #endif // FRAGMENT

            ENDGLSL
        }
        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode" = "ShadowCaster" }

            GLSLPROGRAM

            #ifdef VERTEX
            void main()
            {
                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            void main()
            {
            }
            #endif // FRAGMENT

            ENDGLSL
        }
        // TODO exercise 6 - Add the outline pass here
        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode" = "ForwardBase" }

            Cull Front

            GLSLPROGRAM

            #ifdef VERTEX
            void main()
            {
                vec3 worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
                vec3 normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;

                worldPos += normal * 0.01f;

                gl_Position = unity_MatrixVP * vec4(worldPos, 1.0f);
            }
            #endif // VERTEX

            #ifdef FRAGMENT
            void main()
            {
                gl_FragColor = vec4(0.0f);
            }
            #endif // FRAGMENT

            ENDGLSL
        }
    }
}
