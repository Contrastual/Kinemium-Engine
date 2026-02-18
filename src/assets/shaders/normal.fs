#version 330

in vec3 fragNormal;

out vec4 fragColor;

void main() {
    // Encode normal to 0-1 range
    vec3 normal = normalize(fragNormal);
    fragColor = vec4(normal * 0.5 + 0.5, 1.0);
}