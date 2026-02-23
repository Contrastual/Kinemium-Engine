#version 330

in vec3 fragWorldPos;
in vec3 fragNormal;
in vec2 fragTexCoord;

out vec4 finalColor;

uniform vec3 viewPos;
uniform float time;

void main()
{
    vec3 normal = normalize(fragNormal);

    // Fake moving surface normals
    normal.x += sin(fragWorldPos.x * 3.0 + time * 2.0) * 0.1;
    normal.z += cos(fragWorldPos.z * 3.0 + time * 2.0) * 0.1;
    normal = normalize(normal);

    vec3 viewDir = normalize(viewPos - fragWorldPos);

    // Fresnel
    float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0);

    // Base water color
    vec3 deepColor = vec3(0.0, 0.2, 0.4);
    vec3 shallowColor = vec3(0.0, 0.5, 0.7);

    vec3 color = mix(deepColor, shallowColor, fresnel);

    float alpha = 0.6 + fresnel * 0.3;

    finalColor = vec4(color, alpha);
}