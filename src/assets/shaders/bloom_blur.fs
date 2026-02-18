// shaders/bloom_blur.fs
#version 330

in vec2 fragTexCoord;
uniform sampler2D texture0;  // This will be the extracted bright areas
uniform float intensity;
uniform float radius;

out vec4 fragColor;

// Separable Gaussian blur (horizontal + vertical)
vec3 gaussianBlur(sampler2D tex, vec2 uv, float radius) {
    vec2 texelSize = 1.0 / vec2(textureSize(tex, 0));
    vec3 result = vec3(0.0);
    
    // Gaussian kernel weights
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    
    // Center sample
    result = texture(tex, uv).rgb * weights[0];
    
    // Horizontal + Vertical blur (approximation)
    for(int i = 1; i < 5; i++) {
        // Horizontal
        result += texture(tex, uv + vec2(texelSize.x * float(i) * radius, 0.0)).rgb * weights[i];
        result += texture(tex, uv - vec2(texelSize.x * float(i) * radius, 0.0)).rgb * weights[i];
        
        // Vertical
        result += texture(tex, uv + vec2(0.0, texelSize.y * float(i) * radius)).rgb * weights[i];
        result += texture(tex, uv - vec2(0.0, texelSize.y * float(i) * radius)).rgb * weights[i];
    }
    
    return result * 0.5; // Average horizontal and vertical
}

void main()
{
    vec3 bloom = gaussianBlur(texture0, fragTexCoord, radius);
    
    // texture0 now contains ONLY the extracted bright areas from previous pass
    // We need to add this back to the original scene
    // But the filter system already handles this through ping-ponging
    
    fragColor = vec4(bloom * intensity, 1.0);
}