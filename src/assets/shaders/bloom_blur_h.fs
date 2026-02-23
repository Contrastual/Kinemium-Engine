// shaders/bloom_blur_h.fs - Horizontal Gaussian blur
#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform float radius;

out vec4 fragColor;

void main()
{
    vec2 texelSize = 1.0 / vec2(textureSize(texture0, 0));
    vec3 result = vec3(0.0);
    
    // Gaussian weights
    float weights[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    
    // Center sample
    result = texture(texture0, fragTexCoord).rgb * weights[0];
    
    // Horizontal samples
    for(int i = 1; i < 5; i++) {
        vec2 offset = vec2(texelSize.x * float(i) * radius, 0.0);
        result += texture(texture0, fragTexCoord + offset).rgb * weights[i];
        result += texture(texture0, fragTexCoord - offset).rgb * weights[i];
    }
    
    fragColor = vec4(result, 1.0);
}
