// shaders/bloom.fs
#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform float threshold;
uniform float intensity;
uniform float radius;

out vec4 fragColor;

// Improved Gaussian blur (better quality than box blur)
vec3 gaussianBlur(sampler2D tex, vec2 uv, float radius) {
    vec2 texelSize = 1.0 / vec2(textureSize(tex, 0));
    vec3 result = vec3(0.0);
    float totalWeight = 0.0;
    
    int samples = int(radius);
    for (int x = -samples; x <= samples; x++) {
        for (int y = -samples; y <= samples; y++) {
            // Gaussian weight
            float dist = sqrt(float(x*x + y*y));
            float weight = exp(-dist * dist / (2.0 * radius * radius));
            
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            vec3 sample = texture(tex, uv + offset).rgb;
            
            // Only blur bright pixels
            float brightness = dot(sample, vec3(0.2126, 0.7152, 0.0722));
            if (brightness > threshold) {
                result += sample * weight;
                totalWeight += weight;
            }
        }
    }
    
    return totalWeight > 0.0 ? result / totalWeight : vec3(0.0);
}

void main()
{
    vec3 original = texture(texture0, fragTexCoord).rgb;
    
    // Get blurred bright areas
    vec3 bloom = gaussianBlur(texture0, fragTexCoord, radius);
    
    // Combine with original
    vec3 result = original + bloom * intensity;
    
    fragColor = vec4(result, 1.0);
}