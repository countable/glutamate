
/*
    This file defines some shared stuff for other .fx-files. Note that the data is not
    really shared - each file which includes this will create it's own
    copy of these things.
*/

#define MAX_LIGHT_COUNT 7

//The data in this buffer is updated once for 
//each object (if not using instancing etc.).
cbuffer perObjectBuffer {
    //World matrix
    float4x4 worldMatrix;
    //Combined world-, view- and projection-matrix.
    float4x4 worldViewProjection;
}

//This buffer is updated much more rarely than 'perObjectBuffer'.
cbuffer defaultBuffer  {
    //Combined view and projection matrix
    float4x4 viewProjection;
    //Elapsed time.
    float time = 0.0f; 
    
    //Lightning info.
    float4 lightAmbient = float4(0.2, 0.2, 0.2, 0);
    float3 lightPositions[MAX_LIGHT_COUNT];
    float4 lightColors[MAX_LIGHT_COUNT]; //Values can be over 1.0, not normalized.
    uint lightsActive = 0;
}

/*
    This is EXTREMELY simple lightning model which
    only computes diffuse lightning, specular is not
    computed. This is is a compromise solution
    which is used by many samples so that they don't
    have to clutter their .fx files with this stuff.
    
    If you want to emulate traditional Direct3D 9.x
    pipeline there are several examples floating
    around - 'FixedFuncEMU.fx' from Direct3D SDK
    is included in this folder.
*/

float4 ComputeLight(float3 vertex, float3 normal)
{
    const float attenuation = 0.005f;
    
    float4 result = 0; 
    for (uint i=0; i < lightsActive; ++i) {
        float3 toLight = lightPositions[i] - vertex;
        float lightDist = length(toLight);
        float fAtten = 1.0 / dot(attenuation, float4(1, lightDist, lightDist * lightDist, 0));
        float3 lightDir = normalize(toLight);
        
        //result += max(0, dot( lightDir, normal ) * lightColors[i] * fAtten);
        //result += saturate(dot(lightDir, normal) * lightColors[i] * fAtten);
        result += saturate(max(0, dot(lightDir, normal) * lightColors[i] * fAtten));
    }
    result += lightAmbient;
    
    result.a = 1.0f;
    return result;
}

Texture2D defaultTexture;

SamplerState textureSampler {
    Filter = ANISOTROPIC; // MIN_MAG_MIP_LINEAR
    AddressU = CLAMP; 
    AddressV = CLAMP;
    MaxAnisotropy = 8;
};
