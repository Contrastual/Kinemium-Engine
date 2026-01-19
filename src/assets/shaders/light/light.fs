#version 330

in vec3 fragPos;
in vec3 normal;

out vec4 fragColor;

#define MAX_LIGHTS 128

uniform vec3 lightPos[MAX_LIGHTS];
uniform vec3 lightColor[MAX_LIGHTS];
uniform int lightCount;
uniform vec3 viewPos;
uniform vec3 objectColor;

void main()
{
    vec3 N = normalize(normal);
    vec3 V = normalize(viewPos - fragPos);
    vec3 result = vec3(0.0);

    for (int i = 0; i < lightCount; i++) {
        vec3 L = normalize(lightPos[i] - fragPos);

        // diffuse
        float diff = max(dot(N, L), 0.0);

        // specular
        vec3 R = reflect(-L, N);
        float spec = pow(max(dot(R, V), 0.0), 32.0);

        result += (diff + spec) * lightColor[i];
    }

    result *= objectColor;
    fragColor = vec4(result, 1.0);
}
