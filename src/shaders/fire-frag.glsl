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

uniform float u_FireSpeed;
uniform float u_Height;
uniform float u_Chonk;


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

float ease_in_quadratic(float t) {
    return t * t;
}

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 random3(vec3 st) {
    vec3 random = fract(sin(st * vec3(12.9898, 78.233, 45.5431)) * 43758.5453);
    return normalize(random * 2.0 - 1.0); // Normalize to ensure it's within [-1, 1]
}

float random3to1(vec3 st) {
    vec3 random = fract(sin(st * vec3(12.9898, 78.233, 45.5431)) * 43758.5453);
    return (random.x + random.y * 256.0 + random.z * 65536.0) * 0.00002;
}

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

        vec4 vs_Pos = fs_Pos;
        vec3 pos = vs_Pos.xyz;
        vec4 col = vec4(1.0, 0.6, 0.0, 1.0);
        
        
        vec3 inputColor = vec3(u_Color);
        // make sure input is always at full saturation
        if (inputColor.r >= inputColor.g && inputColor.r >= inputColor.b) {
            inputColor.r = 1.;
        } else if (inputColor.b >= inputColor.g && inputColor.b >= inputColor.r) {
            inputColor.b = 1.;
        } else if (inputColor.g >= inputColor.r && inputColor.g >= inputColor.b) {
            inputColor.g = 1.;
        } else {
            inputColor = vec3(1., 0., 0.);
        }
        

        vec3 ogPos = pos;
        pos.y *= mix(4., (pos.y + 0.), 0.6); 
       // pos.y *= mix(6.5 * (1. - 0.7 * u_Height), (pos.y + 0.), 0.6); 


        
        vec3 stretchedPos = pos;

        float posYForGradient = pos.y * 1.4;
        float gradient = smoothstep(1., 0., posYForGradient);

        float sinTime = 50. * (cos(u_Time * 0.001) + 1.0) ;      

        vec3 posTime = pos;
        posTime.y -= 0.03 * u_Time * (u_FireSpeed ) * 2.;
        posTime.x -= 0.0002 * sinTime;
        posTime.z += 0.0004 * sinTime;

        // Noise output subtracts color to create flames
        float frequency = 2.;
        float noiseOutput = (noise(frequency * posTime)) ;

        //noiseOutput = smoothstep(0.3,0.9,noiseOutput);

        //col.a = noiseOutput;



        // Attempts to make flame cores non-resizeable, doesn't work

        mat3 invTranspose = mat3(u_ModelInvTr);
        vec4 nor = vec4(invTranspose * vec3(fs_Nor), 0);
        vec4 modelposition = u_Model * vec4(pos, 1.);
        vec4 final_pos = u_ViewProj * modelposition;
        

        vec3 center = vec3(0., 0.5, 0.);
        vec3 displacement = final_pos.xyz - center;
        // displacement -= vec3(camScale * u_CameraPos.z);

        //float dispLength = length(displacement) - (camScale * camZ);
        float dispLength = length(displacement) / 1.;



        // Colors

        vec3 black = vec3(0.);
         //black = vec3(mix(0.5, 0.0, ease_in_quadratic(pos.y)));
        vec3 red = vec3(1., 0., 0.);
        red = vec3(0., 0., 1.);
        red = inputColor;
        
        vec3 orange = vec3(1.0, 0.7, 0.0);
        orange = red + vec3(0., 0.7, 0.0);

        vec3 yellow = vec3(1.0, 1.0, 0.0);
        yellow = red + vec3(0., 1.0, 0.0);

        vec3 white = vec3(1.);

        float dispNoise = noise(pos * sinTime);


        dispNoise = sinDisplace(pos.x + pos.z, 0.3, 1., 0.0002) / 2. - 0.1;

      //dispNoise = fbm(pos + sinTime, 0.03) * 4. + 1.;
        dispLength += dispNoise;


        col.rgb = mix(red, black, dispLength - 3.7);


        if (dispLength < 4.2) {
            col.rgb = red;
            col.rgb = mix(orange, red, dispLength * 2. - 7.8);
        }
        if (dispLength < 4.) {
            col.rgb = orange;
            col.rgb = mix(yellow, orange, dispLength * 2. - 7.);

        }
        if (dispLength < 3.7) {
            col.rgb = yellow;
            col.rgb = mix(white, yellow, dispLength * 2. - 6.7);
        }

        if (dispLength < 3.5  ) {
            col.rgb = white;
        }



        // bound at which alpha disappears
        // lower to more black
        float alphaBound = 1.;
        alphaBound -= 0.3 * (stretchedPos.y - 0.3 );

        if (noiseOutput > alphaBound - 0.2) {
            //col.rgb = red;
            col.rgb = mix(red, black, noiseOutput);
                        col.rgb = mix(red, black, (noiseOutput - alphaBound) * 10. + 2.);
        }
        if (noiseOutput > alphaBound) {
            col.rgb = black;
        }
        if (noiseOutput < alphaBound - 0.1 && noiseOutput > alphaBound - 0.2) {
            col.rgb = red;
            col.rgb = mix(red, black, (noiseOutput - alphaBound) * 10. + 2.);
        }

        if (dispLength > 4.2) {
            col.rgb = mix(red, black, dispLength - 3.8);

            float posYForGradient = pos.y * 1.4;
            float gradient = smoothstep(1., 0., posYForGradient);

            col.rgb *= gradient;

        }

        //col.rgb = random3(pos);


        //col.rgb = vec3(fract(noiseOutput));

        // xy difference from center
        //vec2 diff = vec2(pos.x - 10., pos.y - 10.);
        
       // float radius = 1.5;
        //float displacement = (pos.x - radius) * (pos.y - radius);
       // col.rgb *= vec3(displacement);

        //col.r = noiseOutput;
        
        out_Col = col;
}
