
/*
    This file is used by the d3d11x.Sprite-object to render stuff.
*/

cbuffer fontDataBuffer {
    float2 screenSize;
    float4 backgroundColor = {1, 0, 1, 1};
    float4 colorKey = {0, 0, 0, 0};
    int useFilter = 1;
}

Texture2DArray spriteTexture;

SamplerState pointSampler  {
    Filter = MIN_MAG_MIP_POINT; 
};

struct PS_INPUT {
    float4 pos : SV_POSITION;   
    float4 tex : TEXTURE; //x, y, array index, type.
    float4 color : COLOR;
};

//###########################################################################
// Geometry shader version
//###########################################################################

struct VS_GS_INPUT {
    float4 pos : POSITION; // x, y, width and height in screen coordinates.
    float4 color : COLOR; //Color.
    float4 texcoords : TEXAREA; //Texture coordinates for the quad.
    float4 misc : MISC; //italic, texture array index, type, gradient.
    float rotation : ROTATION;
};

//Vertex shader.

VS_GS_INPUT VSSpriteGS(VS_GS_INPUT input)
{
    return input;
}

//Geometry shader stuff.

float2 rotatePoint(float2 p, float2 origin, float degrees)
{
    float2 result;
    result.x = origin.x + (cos(degrees) * (p.x - origin.x) - sin(degrees) * (p.y - origin.y));
    result.y = origin.y + (sin(degrees) * (p.x - origin.x) + cos(degrees) * (p.y - origin.y));
    return result;
}

[maxvertexcount(4)]
void GSSprite(point VS_GS_INPUT input[1], inout TriangleStream<PS_INPUT> stream)
{
    const VS_GS_INPUT v = input[0];
    
    const float italic[4] = {v.misc.x, v.misc.x, 0, 0};
    //Position adjustments.
    const float2 deltas[4] = {
        {0.0, 0.0}, {v.pos.z, 0.0}, 
        {0.0, v.pos.w}, {v.pos.z, v.pos.w}
    };

    //Texture coordinates.
    const float2 texdata[4] = {
        v.texcoords.xy, v.texcoords.zy, 
        v.texcoords.xw, v.texcoords.zw
    };

    const float gradient[4] = {1, 1, v.misc.w, v.misc.w};
    
    //Rotation stuff.
    const float2 origin = float2(v.pos.x + v.pos.z / 2.0, v.pos.y + v.pos.w / 2.0);
    
    for (int i=0; i < 4; ++i) {
        PS_INPUT output;
        
        float2 rotated = rotatePoint(v.pos.xy + deltas[i], origin, v.rotation); 
        output.pos.x = (rotated.x) / (screenSize.x / 2.0) - 1;
        output.pos.y = -((rotated.y) / (screenSize.y / 2.0)) + 1;
        
        //Convert screen coordinates into device coordinates.
        //output.pos.x = (v.pos.x + deltas[i].x + italic[i]) / (screenSize.x / 2.0) - 1;
        //output.pos.y = -((v.pos.y + deltas[i].y) / (screenSize.y / 2.0)) + 1;
        output.pos.z = 0.5;
        output.pos.w = 1.0;
        output.tex = float4(texdata[i], v.misc.y, v.misc.z);

        output.color = v.color;
        output.color.rgb *= gradient[i];
        
        stream.Append(output);
    }
}

//Pixel shader.

float4 PSSprite(PS_INPUT input) : SV_Target
{ 
    float4 textureColor = spriteTexture.Sample(pointSampler, input.tex.xyz);

    if (input.tex.w < 1.0f) {
        //Text.
        //Use black (0, 0, 0) as a "color key" for text.
        if (textureColor.r + textureColor.g + textureColor.b < 0.001)
            discard;
              
        //clip(textureColor.rgb - 0.000001); 
    }
    else if (length(textureColor.rgb - colorKey.rgb) < 0.003) {
        //Rect etc.
        
        //if (textureColor.a < 0.1)
        //    discard;
        clip(-0.1f + textureColor.a);
    }
    textureColor.a = 1.0f;
    
    return textureColor * input.color; 
}

DepthStencilState DisableDepthTestWrite {
    DepthEnable = FALSE;
    DepthWriteMask = ZERO;
    DepthFunc = ALWAYS;
};

RasterizerState RSNormal { 
    CullMode = None; 
    MultisampleEnable = False;
    //FillMode = WireFrame;
    ScissorEnable = True;
};

BlendState BSAlphaBlend {
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA;
    BlendOp = ADD;
    SrcBlendAlpha = ZERO;
    DestBlendAlpha = ZERO;
    BlendOpAlpha = ADD;
    RenderTargetWriteMask[0] = 0x0F;
};

technique11 RenderTextGS {
    pass  {       
        SetVertexShader(CompileShader(vs_4_0, VSSpriteGS())); 
        SetGeometryShader(CompileShader(gs_4_0, GSSprite()));
        SetPixelShader(CompileShader(ps_4_0, PSSprite()));    
    
        SetRasterizerState(RSNormal);
        SetDepthStencilState(DisableDepthTestWrite, 0);
        SetBlendState(BSAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
    }
}
