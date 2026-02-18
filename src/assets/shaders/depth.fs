#version 330

out vec4 fragColor;

void main() {
    // Output linear depth
    fragColor = vec4(vec3(gl_FragCoord.z), 1.0);
}