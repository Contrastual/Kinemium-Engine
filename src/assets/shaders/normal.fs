#version 330

// View-space normal from normal.vs — correct for SSAO depth comparisons
in vec3 fragViewNormal;

out vec4 fragColor;

void main() {
    // Encode view-space normal to 0-1 range so it can be stored in an RGBA8 RT
    vec3 normal = normalize(fragViewNormal);
    fragColor = vec4(normal * 0.5 + 0.5, 1.0);
}