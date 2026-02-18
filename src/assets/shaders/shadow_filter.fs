#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform sampler2D depthTexture;
uniform sampler2D normalTexture;
uniform vec2 resolution;
uniform vec3 lightDir;
uniform float shadowStrength;

out vec4 finalColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec4 sceneColor = texture(texture0, fragTexCoord);
    float depth = texture(depthTexture, fragTexCoord).r;
    vec3 normal = normalize(texture(normalTexture, fragTexCoord).rgb * 2.0 - 1.0);
    
    // Skip sky
    if (depth >= 0.9999) {
        finalColor = sceneColor;
        return;
    }
    
    vec2 texelSize = 1.0 / resolution;
    
    // Sample around pixel in light direction
    float occlusion = 0.0;
    vec2 lightScreenDir = normalize(-lightDir.xy);
    
    const int samples = 8;
    for (int i = 1; i <= samples; i++) {
        vec2 offset = lightScreenDir * texelSize * float(i) * 3.0;
        float sampleDepth = texture(depthTexture, fragTexCoord + offset).r;
        
        // If sample is in front, add occlusion
        if (sampleDepth < depth - 0.0001) {
            occlusion += 1.0;
        }
    }
    
    occlusion /= float(samples);
    
    // Apply shadow
    float shadow = 1.0 - occlusion * shadowStrength;
    
    // Also consider surface facing
    float ndotl = max(dot(normal, normalize(-lightDir)), 0.0);
    shadow = mix(shadow, 1.0, ndotl * 0.5);
    
    finalColor = vec4(sceneColor.rgb * shadow, sceneColor.a);
}