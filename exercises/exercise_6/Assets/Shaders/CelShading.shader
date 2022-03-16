Shader "CG2022/CelShading"
{
	Properties
	{
		_Albedo("Albedo", Color) = (1,1,1,1)
		_AlbedoTexture("Albedo Texture", 2D) = "white" {}
		_Reflectance("Reflectance (Ambient, Diffuse, Specular)", Vector) = (1, 1, 1, 0)
		_SpecularExponent("Specular Exponent", Float) = 100.0
		_Levels("Levels", Int) = 3
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
			uniform int _Levels;
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
					vec2 texCoords;
				};

				#ifdef VERTEX
				out vertexToFragment v2f;

				void main()
				{
					v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
					v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;
					v2f.texCoords = TransformTexCoords(gl_MultiTexCoord0.xy, _AlbedoTexture_ST);

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

					vec3 albedo = texture(_AlbedoTexture, v2f.texCoords).rgb;
					albedo *= _Albedo.rgb;

					float levels = _Levels;

					vec3 lightingColor = vec3(1.0f);

					vec3 lighting = dot(normal, lightDir) * lightingColor;

					float intensity = (ceil(GetColorLuminance(lighting) * levels) / levels);

					if (0.0 >= intensity)
						intensity = 1 / levels;

					vec3 finalColor = intensity * albedo * _LightColor0.rgb;

					gl_FragColor = vec4(finalColor, 1.0f);
				}
				#endif // FRAGMENT

				ENDGLSL
			}

			Pass
			{
				Name "OUTLINE"
				Tags { "LightMode" = "ForwardBase" }


				Cull Front
				GLSLPROGRAM
					

				struct vertexToFragment
				{
					vec3 worldPos;
					vec3 normal;
					vec2 texCoords;
				};

				#ifdef VERTEX
				out vertexToFragment v2f;

				void main()
				{
					v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
					v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;

					v2f.worldPos = v2f.worldPos + (v2f.normal * 0.01f);

					gl_Position = unity_MatrixVP * vec4(v2f.worldPos, 1.0f);
				}
				#endif // VERTEX

				#ifdef FRAGMENT
				in vertexToFragment v2f;

				void main()
				{
					gl_FragColor = vec4(0.0f, 0.0f, 0.0f, 1.0f);
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
					vec2 texCoords;
				};

				#ifdef VERTEX
				out vertexToFragment v2f;

				void main()
				{
					v2f.worldPos = (unity_ObjectToWorld * gl_Vertex).xyz;
					v2f.normal = (unity_ObjectToWorld * vec4(gl_Normal, 0.0f)).xyz;
					v2f.texCoords = TransformTexCoords(gl_MultiTexCoord0.xy, _AlbedoTexture_ST);

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

					vec3 albedo = texture(_AlbedoTexture, v2f.texCoords).rgb;
					albedo *= _Albedo.rgb;

					vec3 lightingColor = vec3(1.0f);

					vec3 lighting = dot(normal, lightDir) * lightingColor;

					float intensity = ceil(GetColorLuminance(lighting) * _Levels) / _Levels;

					vec3 finalColor = intensity * albedo * _LightColor0.rgb;

					gl_FragColor = vec4(finalColor, 1.0f);
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
		}
}
