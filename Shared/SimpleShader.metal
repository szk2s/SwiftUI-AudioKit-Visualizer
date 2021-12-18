//
//  SimpleShader.metal
//  Visualizer
//
//  Created by okuyama on 2021/12/16.
//

#include <metal_stdlib>
using namespace metal;


struct ColorInOut{
    float4 position[[position]];
    float2 texCoords;
};

vertex ColorInOut vertexShader(constant float4 *positions[[buffer(0)]],
                               constant float2 *texCoords[[buffer(1)]],
                            
                               uint vid         [[vertex_id]]){
    ColorInOut out;
    out.position = positions[vid];
    out.texCoords = texCoords[vid];
    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<float> texture[[texture(0)]],
                               constant float* amplitudes[[buffer(0)]]
                               ){
    
    float arrayNum = 150.0;
    int index =floor(in.texCoords.x*arrayNum);
    float amplitudeValue = amplitudes[index];
    float height = (amplitudeValue<(1.0-in.texCoords.y))?0.0:1.0;

    return float4(0.0,0.0,height,1);
}
