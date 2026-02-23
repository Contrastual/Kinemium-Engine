#version 330

in vec3 fragPos;
in vec3 normal;

out vec4 finalColor;

uniform vec3 viewPos;
uniform vec3 tintColor;
uniform samplerCube environmentMap;

void main()
{
    vec3 N = normalize(normal);
    vec3 V = normalize(viewPos - fragPos);

    // Fresnel (Schlick approximation)
    float fresnel = pow(1.0 - max(dot(N, V), 0.0), 5.0);

    // Reflection
    vec3 R = reflect(-V, N);
    vec3 reflection = texture(environmentMap, R).rgb;

    // Mix tint and reflection
    vec3 color = mix(tintColor, reflection, fresnel);

    finalColor = vec4(color, 0.4); // transparency
}