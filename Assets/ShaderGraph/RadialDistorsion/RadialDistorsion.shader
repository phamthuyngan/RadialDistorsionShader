Shader "Hidden/Shader/RadialDistorsion"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    // List of properties to control your post process effect
    float _Intensity, _Radius, _CenterX, _CenterY, _RaysStrength;
    int _IsDebug, _RaysNumber, _Samples;
    TEXTURE2D_X(_InputTexture);

    float angle(float2 vector1)
    {
        return asin(normalize(vector1).y);
    }

    float rays(float2 vector1)
    {
        return 1 - (sin((angle(vector1)) * _RaysNumber)/2 + 0.5) * _RaysStrength;
    }

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        float3 outColor = float3(0,0,0);

        float2 center = float2(_CenterX, _CenterY);
        float2 dir = input.texcoord - center;
        float2 uv = input.texcoord * _ScreenSize.xy;

        float vignette = saturate(distance(input.texcoord, center) - _Radius);
        float scale = _Intensity * vignette * rays(dir);
        float2 blurOffset = normalize(dir) * saturate(scale);
                  if(_IsDebug == 0)
                   {
                       for(int i = 0; i < _Samples; i++)
                       {
                            outColor += LOAD_TEXTURE2D_X(_InputTexture,clamp( uv - (dir * scale) + i * blurOffset, float2(0,0), _ScreenSize.xy * 0.9995)).xyz;
                       }
                        outColor /= _Samples;
                  }
                  else
                    outColor = scale;
        return float4(outColor, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "RadialDistorsion"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }
    Fallback Off
}
