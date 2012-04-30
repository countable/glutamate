
#include "Shared.fx"

struct InstanceData {
    row_major float4x4 worldMatrix;
};

cbuffer instanceBuffer {
    //MESH_MAX_INSTANCE_COUNT is defined by the application.
    InstanceData instanceData[MESH_MAX_INSTANCE_COUNT];
}

struct VS_INPUT {
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 tex : TEXTURE;
    uint instanceId : SV_InstanceID; //Only used when instancing.
};

struct VS_OUTPUT {
    float4 position : SV_POSITION;   
    float4 color : COLOR;
    float2 tex : TEXTURE;
};

VS_OUTPUT RenderMeshInstancedVS(VS_INPUT input)
{
    VS_OUTPUT output;
    //World space transform.
    output.position = mul(input.position, instanceData[input.instanceId].worldMatrix);
    
    //Compute normals and lightning (in world space).
    float3 normal = mul(input.normal, (float3x3)instanceData[input.instanceId].worldMatrix);
    output.color = ComputeLight(output.position.xyz, normal);
    
    //Apply view and projection matrix.
    output.position = mul(output.position, viewProjection); 
    
    output.tex = input.tex;
    return output;   
}

VS_OUTPUT RenderMeshVS(VS_INPUT input)
{
    VS_OUTPUT output;
    output.position = mul(input.position, worldMatrix);
    
    float3 normal = mul(input.normal, (float3x3)worldMatrix);
    output.color = ComputeLight(output.position.xyz, normal);
    
    output.position = mul(output.position, viewProjection);
    output.tex = input.tex;
    return output;    
}

float4 RenderMeshPS(VS_OUTPUT input) : SV_Target
{ 
    return defaultTexture.Sample(textureSampler, input.tex) * input.color;
}

RasterizerState RSNormal { 
    CullMode = FRONT; 
    MultisampleEnable = True;
    //FillMode = WireFrame;
    //ScissorEnable = True;
};

technique11 RenderMeshSingle {
    pass  {       
        SetVertexShader(CompileShader(vs_4_0, RenderMeshVS())); 
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, RenderMeshPS()));    
    
        SetRasterizerState(RSNormal);
    }
}

technique11 RenderMeshInstanced {
    pass  {       
        SetVertexShader(CompileShader(vs_4_0, RenderMeshInstancedVS())); 
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, RenderMeshPS()));    
    
        SetRasterizerState(RSNormal);
    }
}
