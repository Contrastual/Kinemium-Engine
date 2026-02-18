// shaders/sunrays.fs
#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform vec2 sunScreenPos;
uniform float density;
uniform float weight;
uniform float decay;
uniform float exposure;
uniform float threshold; // New: brightness threshold for rays

out vec4 fragColor;

#define NUM_SAMPLES 100

void main()
{
    // Calculate ray direction and step size
    vec2 deltaTexCoord = (fragTexCoord - sunScreenPos);
    float rayDistance = length(deltaTexCoord);
    deltaTexCoord *= 1.0 / float(NUM_SAMPLES) * density;

    vec2 texCoord = fragTexCoord;
    float illuminationDecay = 1.0;
    vec3 color = vec3(0.0);

    // Distance-based attenuation for more realistic falloff
    float distanceAttenuation = 1.0 - smoothstep(0.0, 1.5, rayDistance);
    
    // Sample along ray from pixel to sun
    for(int i = 0; i < NUM_SAMPLES; i++)
    {
        texCoord -= deltaTexCoord;
        
        // Clamp texture coordinates to avoid sampling outside bounds
        if(texCoord.x < 0.0 || texCoord.x > 1.0 || 
           texCoord.y < 0.0 || texCoord.y > 1.0)
            break;
        
        vec3 sample = texture(texture0, texCoord).rgb;
        
        // Optional: Apply brightness threshold to only scatter bright areas
        float brightness = dot(sample, vec3(0.299, 0.587, 0.114));
        float thresholdMask = smoothstep(threshold - 0.1, threshold + 0.1, brightness);
        sample *= thresholdMask;
        
        // Apply decay and weight
        sample *= illuminationDecay * weight;
        color += sample;
        illuminationDecay *= decay;
    }

    // Apply distance-based attenuation
    color *= distanceAttenuation;

    // Combine with original
    vec3 original = texture(texture0, fragTexCoord).rgb;
    
    // Optional: Blend mode options
    // Additive (current):
    vec3 finalColor = original + color * exposure;
    
    // Screen blend (softer):
    // vec3 finalColor = 1.0 - (1.0 - original) * (1.0 - color * exposure);
    
    fragColor = vec4(finalColor, 1.0);
}