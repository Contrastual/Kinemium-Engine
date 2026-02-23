#version 330

in vec3 vertexPosition;
in vec3 vertexNormal;
in vec2 vertexTexCoord;

uniform mat4 mvp;
uniform mat4 matModel;
uniform float time;

out vec3 fragWorldPos;
out vec3 fragNormal;
out vec2 fragTexCoord;

void main()
{
    vec3 pos = vertexPosition;

    // World position
    vec4 worldPos = matModel * vec4(pos, 1.0);

    // --- Wave calculation ---
    float wave1 = sin(worldPos.x * 0.8 + time * 1.5) * 0.15;
    float wave2 = cos(worldPos.z * 1.2 + time * 1.2) * 0.12;
    float wave3 = sin((worldPos.x + worldPos.z) * 0.5 + time * 0.8) * 0.08;

    worldPos.y += wave1 + wave2 + wave3;

    fragWorldPos = worldPos.xyz;
    fragNormal = normalize(mat3(matModel) * vertexNormal);
    fragTexCoord = vertexTexCoord;

    gl_Position = mvp * vec4(worldPos.xyz, 1.0);
}