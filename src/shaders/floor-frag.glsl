#version 300 es

precision highp float;
uniform vec4 u_Color;

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj; 
uniform float u_Time;
in vec4 vs_Pos;
//in vec4 vs_Nor;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; 

uniform float u_Chonk;


float sinDisplace(float x, float amplitude, float frequency, float timeFactor) {
    
    float y = sin(x * frequency);
    float t = timeFactor*(-u_Time*130.0);
    y += sin(x*frequency*2.1 + t)*4.5;
    y += sin(x*frequency*1.72 + t*1.121)*4.0;
    y += sin(x*frequency*2.221 + t*0.437)*5.0;
    y += sin(x*frequency*3.1122+ t*4.269)*2.5;
    y *= amplitude*0.06;
    return y;
}

float bias (float b, float t) {
    return pow (t, log(b) / log(0.5f));
}

float gain (float g, float t) {
    if (t < 0.5f) {
        return bias(1. - g, 2. * t) / 2.;
    } else {
        return 1. - bias(1. - g, 2. - 2. * t) / 2.;
    }
}

void main()
{
    vec3 col = vec3(0.1);
    vec3 center = vec3(0.);

    vec3 pos = fs_Pos.xyz;

    vec3 orange = vec3(0.6, 0.2, 0.1);
    orange = vec3(u_Color);
    orange -= vec3(0.4);
    if (orange.x < 0.) {
        orange.x = 0.;
    }
    if (orange.y < 0.) {
        orange.y = 0.;
    }
    if (orange.z < 0.) {
        orange.z = 0.;
    }

    float distance =  length(abs(pos.xz)) * 2.5;
    distance *= (1.2 - u_Chonk )  * 2. - 0.;
    //distance = smoothstep(0., 1., distance);
    distance = bias(0.6, distance);


    float distanceNoise = sinDisplace(distance, 1., 0.3, 0.0003);
    distance += 0.3*distanceNoise;

    
//     distance = distance* sin(u_Time*0.05);

    col = vec3(mix(orange, vec3(0.), distance));


    out_Col = vec4(col, 1.);
}
