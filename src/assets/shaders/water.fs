#version 330

in vec2 fragTexCoord;
in vec3 fragNormal;
in vec3 fragPosition;

uniform float time;           // Increment this each frame
uniform vec3 cameraPos;       // World-space camera position
uniform sampler2D texture0;   // Optional: water normal map or surface texture

out vec4 fragColor;

void main()
{
    // Simple wave movement
    float wave = sin(fragPosition.x * 0.3 + time) * 0.05 +
                 cos(fragPosition.z * 0.2 + time * 1.3) * 0.05;

    // Adjust normal with wave (fake normals)
    vec3 normal = normalize(fragNormal + vec3(0.0, wave, 0.0));

    // Simple reflection using Fresnel
    vec3 viewDir = normalize(cameraPos - fragPosition);
    float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0);

    // Base water color
    vec3 waterColor = vec3(0.0, 0.3, 0.5);

    // Add simple lighting (sun from above)
    vec3 lightDir = normalize(vec3(0.0, 1.0, 0.0));
    float diffuse = max(dot(normal, lightDir), 0.0);

    // Combine water color, lighting, and Fresnel for reflectiveness
    fragColor = vec4(waterColor * diffuse + vec3(fresnel), 1.0);
}
