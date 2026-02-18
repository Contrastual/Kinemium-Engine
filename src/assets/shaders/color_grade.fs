// shaders/color_grade.fs
#version 330

in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform float contrast;    // e.g., 1.1
uniform float saturation;  // e.g., 1.2
uniform float brightness;  // e.g., 1.0
uniform vec3 tint;         // e.g., (1.0, 0.95, 0.9) for warm

out vec4 fragColor;

void main()
{
    vec3 color = texture(texture0, fragTexCoord).rgb;
    
    // Brightness
    color *= brightness;
    
    // Contrast
    color = (color - 0.5) * contrast + 0.5;
    
    // Saturation
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, saturation);
    
    // Tint
    color *= tint;
    
    fragColor = vec4(1.0, 0.0, 1.0, 1.0);
}