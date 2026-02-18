#version 330

out vec4 fragColor;

uniform float near = 0.1;   // raise this - 0.01 is brutal for precision
uniform float far  = 300.0; // lower this to match your actual scene range

void main() {
    float z = gl_FragCoord.z * 2.0 - 1.0;  // back to NDC [-1, 1]
    float linearDepth = (2.0 * near * far) / (far + near - z * (far - near));
    float normalized = linearDepth / far;   // remap to [0, 1]
    fragColor = vec4(vec3(normalized), 1.0);
}