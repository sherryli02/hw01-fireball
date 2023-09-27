#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform float u_Time;
in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;
out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1);

uniform float u_Wind_Random;
uniform float u_Wind_LR;

uniform float u_Height;
uniform float u_Chonk;





// https://thebookofshaders.com/13/
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

vec3 random3(vec3 st) {
    vec3 random = fract(sin(st * vec3(12.9898, 78.233, 45.5431)) * 43758.5453);
    return normalize(random * 2.0 - 1.0); // Normalize to ensure it's within [-1, 1]

}

// interpolate between 8 surrounding corners
float noise(vec3 st) {
    vec3 i = floor(st);
    vec3 f = fract(st);

    vec3 u = f * f * (3.0 - 2.0 * f);

    float c1 = dot(random3(i), f - vec3(0.0, 0.0, 0.0));
    float c2 = dot(random3(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0));
    float c3 = dot(random3(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0));
    float c4 = dot(random3(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0));
    float c5 = dot(random3(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0));
    float c6 = dot(random3(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0));
    float c7 = dot(random3(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0));
    float c8 = dot(random3(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0));

    return mix(
        mix(mix(c1, c2, u.x), mix(c3, c4, u.x), u.y),
        mix(mix(c5, c6, u.x), mix(c7, c8, u.x), u.y),
        u.z
    ) * 0.5 + 0.5; // Normalize to [0, 1]
}

float fbm(vec3 st, float baseFrequency) {
    float total = 0.0;
    float persistence = 0.5;

    for (int i = 0; i < 5; ++i) {
        float frequency = pow(2.0, float(i)) * baseFrequency; // Scale the frequency
        float amplitude = pow(persistence, float(i));

        // Accumulate contributions in total
        total += amplitude * noise(st * frequency);

        // Update the input coordinates for the next octave
        st *= 2.0;
    }
    return total - 1.0; // Adjusting to your desired range
}



void main()
{
    fs_Col = vs_Col;
    fs_Pos = vs_Pos;
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);
    vec4 modelposition = u_Model * vs_Pos;

    vec3 pos = vec3(modelposition);



    // Stretch into teardrop shape
    pos.xz *= vec2(u_Chonk * 0.7 );

    pos *= vec3(2.2, 1.2, 2.2); // fatten

    // stretch top half
    pos *= vec3(1.0, mix(4., (pos.y + 0.), 0.6), 1.0); 
    
   // pos.y *= mix(6.5 * (1. - 0.7 * u_Height), (pos.y + 0.), 0.6); 

    pos.y *= u_Height * 2.;
    pos.y += u_Height - 0.5;


    
    //pos += vec3(0.0, -1.0, 0.);
    vec3 ogPos = pos;
    

    // Low-freq, high-amp displacement

    vec3 lowFHighA = pos;
    lowFHighA.x += sinDisplace(pos.x, 0.3, 1., 0.0001);
    lowFHighA.z -= sinDisplace(pos.z, 0.4, 0.9, 0.00009);
    lowFHighA.y += -sinDisplace(pos.y, 0.1, 2.5, 0.0002);
    pos = lowFHighA;

    // High-freq, low-amp displacement

    vec3 highFLowA = pos;
    //float sinTime = sin(u_Time * 0.01) + 1.;

    float sinTime = 0.03 * sinDisplace(pos.x, 0.3, 1., 0.00009);
    float fbmOutput = 3.0 * fbm(pos.xyz, sinTime)+ 1. ;

    highFLowA = pos * vec3(fbmOutput);
    //highFlowA = mix(pos, fbmOutput, vec3(0.1));
    pos = highFLowA;

    // Left-right motion (wind)
    vec3 windNoise = pos;
    float yFactor = pos.y + 1.;

    
    float windControl = 18. * (u_Wind_Random);
    windNoise.x += windControl * .05 * sinDisplace(1., yFactor, 1., 0.00008);
   // windNoise.x *= u_Wind_Random;
   

    pos = windNoise;
    pos.x += yFactor * (u_Wind_LR - 0.5);


    // Stabilize bottom of flame
    // pos = mix(ogPos, pos, ogPos.y + 0.2); 


    modelposition = vec4(pos, 1.);

    gl_Position = u_ViewProj * modelposition;
}
