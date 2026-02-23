#version 330

// ssao.frag — Screen-Space Ambient Occlusion
// Reads: depthTexture (hardware depth), normalTexture (view-space normals 0-1)
// Outputs: greyscale AO mask (1.0 = fully lit, 0.0 = fully occluded)
// Composited via multiply-blend in KI3D.

// SSAO tuning
// Near/far MUST match Raylib's actual clip planes (rlGetCullDistanceNear/Far defaults)
const float NEAR = 0.01;   // Raylib default near plane
const float FAR  = 1000.0; // Raylib default far plane

// Tuning
const int   KERNEL_SIZE = 24;
const float RADIUS      = 0.05;  // UV-space radius (~5% of screen) — 0.4 was 40% = too large
const float BIAS        = 0.020;

uniform sampler2D depthTexture;
uniform sampler2D normalTexture;
uniform vec2      resolution;

noperspective in vec2 texCoord;
out vec4 fragColor;

// ─── Depth helpers ────────────────────────────────────────────────────────────

float getDepth(vec2 uv) {
    return texture(depthTexture, uv).r;
}

// Standard perspective-correct linearisation
float lineariseDepth(float depth) {
    return (2.0 * NEAR * FAR) / (FAR + NEAR - (2.0 * depth - 1.0) * (FAR - NEAR));
}

// Returns negative view-space Z for the given UV
float getViewZ(vec2 uv) {
    float d = getDepth(uv);
    if (d >= 0.9999) return -1000.0;   // sky / background sentinel
    return -lineariseDepth(d);
}

// ─── Normal helpers ───────────────────────────────────────────────────────────

// Decode view-space normal from the 0-1 encoded normalTexture
vec3 getViewNormal(vec2 uv) {
    return normalize(texture(normalTexture, uv).rgb * 2.0 - 1.0);
}

// ─── Noise ────────────────────────────────────────────────────────────────────

// Low-cost per-pixel random rotation angle to reduce banding
float hashAngle(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453) * 6.283185;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
    vec2 uv = texCoord;

    float centerDepth = getDepth(uv);

    // Background / sky: no occlusion (geometry has gl_FragCoord.z 0.97-0.9998 typical)
    if (centerDepth >= 0.9999) {
        fragColor = vec4(1.0);
        return;
    }

    float centerZ  = getViewZ(uv);
    vec3  normal   = getViewNormal(uv);

    // Per-pixel random TBN — breaks up sampling pattern to hide repetition
    float angle     = hashAngle(uv * resolution);
    vec3  randomVec = vec3(cos(angle), sin(angle), 0.0);
    vec3  tangent   = normalize(randomVec - normal * dot(randomVec, normal));
    vec3  bitangent = cross(normal, tangent);
    mat3  TBN       = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;

    for (int i = 0; i < KERNEL_SIZE; i++) {
        // Fibonacci hemisphere spiral (good coverage with few samples, no texture needed)
        float fi    = float(i);
        float theta = fi * 2.399963;     // golden angle in radians
        float r     = sqrt(fi / float(KERNEL_SIZE));

        // Sample in the oriented hemisphere
        vec3 sampleDir = TBN * vec3(
            r * cos(theta),
            r * sin(theta),
            sqrt(max(0.0, 1.0 - r * r))
        );

        vec2 sampleUV = clamp(uv + sampleDir.xy * RADIUS, 0.001, 0.999);
        float sampleZ = getViewZ(sampleUV);

        // Smooth falloff: ignore samples too far away in depth
        float rangeCheck = smoothstep(0.0, 1.0, RADIUS / (abs(centerZ - sampleZ) + 0.001));

        // Count occluded samples (sample is closer to camera than surface)
        if ((centerZ - sampleZ) > BIAS && sampleZ > -900.0) {
            occlusion += rangeCheck;
        }
    }

    // Normalise, invert (1 = no occlusion), boost contrast
    float ao = 1.0 - (occlusion / float(KERNEL_SIZE));
    ao = pow(smoothstep(0.0, 1.0, ao), 1.5);

    fragColor = vec4(ao, ao, ao, 1.0);
}
