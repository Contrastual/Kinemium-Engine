#version 330

in vec3 vertexPosition;
in vec3 vertexNormal;

uniform mat4 matModel;
uniform mat4 matView;
uniform mat4 matProjection;
uniform mat4 matNormal;

// World-space normal (for general use by default_lit etc.)
out vec3 fragNormal;
// View-space normal (consumed by SSAO — view-space depth comparisons are correct)
out vec3 fragViewNormal;

void main() {
    vec3 worldNormal  = normalize(vec3(matNormal * vec4(vertexNormal, 0.0)));
    fragNormal        = worldNormal;
    fragViewNormal    = normalize((matView * vec4(worldNormal, 0.0)).xyz);

    gl_Position = matProjection * matView * matModel * vec4(vertexPosition, 1.0);
}