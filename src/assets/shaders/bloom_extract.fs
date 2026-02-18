// shaders/bloom_extract.fs
#version 330

in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform float threshold;

out vec4 fragColor;

void main()
{
    vec3 color = texture(texture0, fragTexCoord).rgb;
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    
    // Only keep pixels brighter than threshold
    if (brightness > threshold) {
        // Scale brightness above threshold
        float excess = (brightness - threshold) / max(1.0 - threshold, 0.001);
        fragColor = vec4(color * excess, 1.0);
    } else {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}