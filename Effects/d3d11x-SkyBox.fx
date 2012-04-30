
#include "Shared.fx"

struct VS_INPUT {
    float4 position : POSITION;
    float3 tex : TEXTURE; // .z is the texture array index. Not currently used in shader.
};

struct VS_OUTPUT {
    float4 position : SV_POSITION;   
    float4 color : COLOR;
    float3 tex : TEXTURE;
};

SamplerState skySampler {
    Filter = MIN_MAG_MIP_LINEAR; // MIN_MAG_MIP_LINEAR
    AddressU = CLAMP; 
    AddressV = CLAMP;
};

VS_OUTPUT RenderSkyboxVS(VS_INPUT input)
{
    VS_OUTPUT output;
    output.position = mul(input.position, worldViewProjection);
    //output.position.z = 0.0f;
    output.color = lightAmbient;
    output.tex = input.tex;
    return output;    
}

float4 RenderSkyboxPS(VS_OUTPUT input) : SV_Target
{ 
    return defaultTexture.Sample(skySampler, input.tex.xy);// * input.color;
}

RasterizerState RSNormal { 
    CullMode = None; 
    MultisampleEnable = True;
};

DepthStencilState DisableDepthTestWrite {
    DepthEnable = FALSE;
    DepthWriteMask = ZERO;
    DepthFunc = ALWAYS;
};

technique11 RenderSkyBox {
    pass  {       
        SetVertexShader(CompileShader(vs_4_0, RenderSkyboxVS())); 
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, RenderSkyboxPS()));    
    
        SetRasterizerState(RSNormal);
        SetDepthStencilState(DisableDepthTestWrite, 0);
    }
}
