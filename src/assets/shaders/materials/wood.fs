#version 330

in vec3 fragPos;
in vec3 fragNormal;

uniform vec3 cameraPos;

out vec4 fragColor;

// Hash + smooth noise
float hash(vec3 p)
{
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p)
{
    vec3 i = floor(p);
    vec3 f = fract(p);

    float n = mix(
        mix(
            mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x),
            f.y),
        mix(
            mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x),
            f.y),
        f.z);

    return n;
}

// Fractal Brownian Motion
float fbm(vec3 p)
{
    float v = 0.0;
    float a = 0.5;
    for(int i = 0; i < 5; i++)
    {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main()
{
    vec3 N = normalize(fragNormal);
    vec3 V = normalize(cameraPos - fragPos);

    // --- Grain Direction ---
    // Stretch noise heavily along X axis (plank direction)
    vec3 grainCoord = vec3(fragPos.x * 0.2,
                           fragPos.y * 4.0,
                           fragPos.z * 4.0);

    float grain = fbm(grainCoord);

    // Subtle ring modulation (not circular)
    float rings = sin(fragPos.x * 6.0 + grain * 2.0);
    rings = 0.5 + 0.5 * rings;

    // Break up uniformity
    float variation = fbm(fragPos * 2.0);

    // --- Realistic Wood Colors ---
    vec3 baseLight = vec3(0.52, 0.32, 0.18);  // oak tone
    vec3 baseDark  = vec3(0.30, 0.17, 0.08);

    vec3 woodColor = mix(baseDark, baseLight, rings);
    woodColor *= 0.85 + variation * 0.3;

    // --- Roughness Simulation ---
    float roughness = 0.6 + grain * 0.2;

    // --- Lighting (Cook-Torrance inspired simplified) ---
    vec3 lightDir = normalize(vec3(0.4, 1.0, 0.3));
    float NdotL = max(dot(N, lightDir), 0.0);

    vec3 halfDir = normalize(lightDir + V);
    float NdotH = max(dot(N, halfDir), 0.0);

    float specPower = mix(16.0, 4.0, roughness);
    float spec = pow(NdotH, specPower) * 0.15;

    vec3 diffuse = woodColor * NdotL;

    vec3 finalColor = diffuse + spec;

    fragColor = vec4(finalColor, 1.0);
}