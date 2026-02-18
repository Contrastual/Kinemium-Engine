#version 330

in vec3 vNormal;
in vec3 vWorldPos;
in vec2 vTexCoord;
in vec4 vColor;
in vec4 vLightSpacePos;

uniform sampler2D texture0;
uniform sampler2D shadowMap;
uniform vec3 globalAmbient;
uniform vec3 dirLightDir;
uniform vec3 dirLightColor;
uniform float brightness;
uniform vec3 viewPos;
uniform float shadowBias;
uniform float shadowStrength;

// Increased light capacity
#define MAX_LIGHTS 64
uniform int lightCount;

// Packed light data for better cache coherency
uniform vec4 lightPosRange[MAX_LIGHTS];      // xyz = position, w = range
uniform vec4 lightColorIntensity[MAX_LIGHTS]; // rgb = color, a = intensity

out vec4 fragColor;

const float PI = 3.14159265359;

// Fast hash
float Hash12(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Optimized directional shadow - adaptive quality based on distance
float DirectionalShadowFactor(vec3 normal, vec3 lightDir)
{
    vec3 projCoords = vLightSpacePos.xyz / vLightSpacePos.w;
    projCoords = projCoords * 0.5 + 0.5;

    if (projCoords.z > 1.0 || projCoords.x < 0.0 || projCoords.x > 1.0 ||
        projCoords.y < 0.0 || projCoords.y > 1.0)
        return 1.0;

    float sunHeight = clamp(lightDir.y, 0.0, 1.0);
    float dayFactor = smoothstep(0.02, 0.18, sunHeight);

    float slope = 1.0 - dot(normal, lightDir);
    float bias = max(shadowBias * (0.5 + slope), shadowBias * 0.5);
    bias *= mix(2.2, 1.0, sunHeight);

    // Distance-based quality
    float distToEdge = min(min(projCoords.x, 1.0 - projCoords.x), 
                           min(projCoords.y, 1.0 - projCoords.y));
    int samples = distToEdge > 0.1 ? 4 : 9; // Use fewer samples far from edges
    
    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    float softness = mix(2.2, 0.9, sunHeight);
    
    // Optimized sampling pattern
    if (samples == 4) {
        // 2x2 grid for distant shadows
        for (int x = 0; x <= 1; ++x) {
            for (int y = 0; y <= 1; ++y) {
                vec2 offset = vec2(x - 0.5, y - 0.5) * texelSize * softness;
                float pcfDepth = texture(shadowMap, projCoords.xy + offset).r;
                shadow += (projCoords.z - bias) > pcfDepth ? 1.0 : 0.0;
            }
        }
        shadow /= 4.0;
    } else {
        // 3x3 grid for close shadows
        for (int x = -1; x <= 1; ++x) {
            for (int y = -1; y <= 1; ++y) {
                vec2 offset = vec2(x, y) * texelSize * softness;
                float pcfDepth = texture(shadowMap, projCoords.xy + offset).r;
                shadow += (projCoords.z - bias) > pcfDepth ? 1.0 : 0.0;
            }
        }
        shadow /= 9.0;
    }

    float strength = shadowStrength * dayFactor;
    return 1.0 - shadow * strength;
}

// Fresnel-Schlick approximation
vec3 FresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// Optimized GGX - reduced precision for performance
float DistributionGGX(float NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;

    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / max(denom, 0.0001);
}

// Simplified geometry function
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) * 0.125; // Optimized constant

    return NdotV / (NdotV * (1.0 - k) + k);
}

float GeometrySmith(float NdotV, float NdotL, float roughness)
{
    return GeometrySchlickGGX(NdotV, roughness) * GeometrySchlickGGX(NdotL, roughness);
}

void main()
{
    vec4 texColor = texture(texture0, vTexCoord);
    vec3 albedo = texColor.rgb * vColor.rgb;
    vec3 N = normalize(vNormal);
    vec3 V = normalize(viewPos - vWorldPos);

    // Material properties
    float roughness = 0.5;
    float metallic = 0.0;
    
    vec3 F0 = mix(vec3(0.04), albedo, metallic);

    // Directional light (sun/moon)
    vec3 L = normalize(-dirLightDir);
    vec3 H = normalize(L + V);
    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float HdotV = max(dot(H, V), 0.0);
    
    // Cook-Torrance for directional
    float NDF = DistributionGGX(NdotH, roughness);
    float G = GeometrySmith(NdotV, NdotL, roughness);
    vec3 F = FresnelSchlick(HdotV, F0);
    
    vec3 kS = F;
    vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);
    
    vec3 numerator = NDF * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.0001;
    vec3 specular = numerator / denominator;
    
    float shadow = DirectionalShadowFactor(N, L);
    vec3 directionalLight = (kD * albedo / PI + specular) * dirLightColor * NdotL * brightness * shadow;

    // Point lights - optimized loop with early rejection
    vec3 pointLight = vec3(0.0);
    int count = min(lightCount, MAX_LIGHTS);
    
    // Pre-calculate view-dependent terms
    float invRoughness = 1.0 / max(roughness, 0.01);
    
    for (int i = 0; i < count; i++)
    {
        // Unpack light data
        vec3 lightPos = lightPosRange[i].xyz;
        float lightRange = lightPosRange[i].w;
        vec3 lightColor = lightColorIntensity[i].rgb;
        float lightIntensity = lightColorIntensity[i].a;
        
        // Early distance rejection
        vec3 Lp = lightPos - vWorldPos;
        float dist = length(Lp);
        
        if (dist > lightRange) continue; // Skip lights out of range
        
        vec3 Ldir = Lp / dist; // Normalize (reuse distance calc)
        
        // Physically-based attenuation with smooth falloff
        float distRatio = dist / lightRange;
        if (distRatio > 1.0) continue; // Double-check
        
        float attenuation = 1.0 / (dist * dist + 1.0); // Avoid division by zero
        float smoothFalloff = 1.0 - smoothstep(0.7, 1.0, distRatio);
        attenuation *= smoothFalloff;
        
        float NdotLp = dot(N, Ldir);
        if (NdotLp <= 0.0) continue; // Skip lights behind surface
        
        vec3 radiance = lightColor * lightIntensity * attenuation;
        
        // Simplified specular for point lights (performance optimization)
        vec3 Hp = normalize(Ldir + V);
        float NdotHp = max(dot(N, Hp), 0.0);
        float HdotVp = max(dot(Hp, V), 0.0);
        
        // Simplified BRDF for point lights
        float NDFp = DistributionGGX(NdotHp, roughness);
        float Gp = GeometrySmith(NdotV, NdotLp, roughness);
        vec3 Fp = FresnelSchlick(HdotVp, F0);
        
        vec3 kSp = Fp;
        vec3 kDp = (vec3(1.0) - kSp) * (1.0 - metallic);
        
        vec3 specularp = (NDFp * Gp * Fp) / (4.0 * NdotV * NdotLp + 0.0001);
        
        pointLight += (kDp * albedo / PI + specularp) * radiance * NdotLp;
    }

    // Ambient
    vec3 ambient = albedo * globalAmbient * (0.3 + 0.7 * (1.0 - metallic));
    
    vec3 color = ambient + directionalLight + pointLight;
    
    // Tone mapping (optimized)
    color = color / (color + 1.0);
    
    // Gamma correction
    color = pow(color, vec3(0.4545)); // 1/2.2 as constant

    fragColor = vec4(color, texColor.a * vColor.a);
}