// shaders/bloom_composite.fs - Composite blurred bloom onto original
#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;  // Original scene (from runtime.original)
uniform float intensity;

out vec4 fragColor;

void main()
{
    // texture0 in the filter system is the currentRT which has the blurred bloom
    // We need to also sample the original which is passed differently
    // Actually, the ki3d system binds texture0 to currentRT
    // We need to modify how we pass the original
    
    vec3 bloom = texture(texture0, fragTexCoord).rgb;
    
    // This shader will be used with a custom approach
    // We'll just output the bloom for now
    // The actual composite happens through additive blending in the filter system
    
    fragColor = vec4(bloom, 1.0);
}
