#version 330

layout (location = 0) in vec3 vertexPosition;
layout (location = 1) in vec2 vertexTexCoord;
layout (location = 2) in vec3 vertexNormal;
layout (location = 3) in vec4 vertexColor;

// mat4 = 4 vec4 attributes
layout (location = 4) in mat4 instanceTransform;
layout (location = 8) in vec4 instanceColor;

out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;
out vec3 fragPosition;

uniform mat4 matView;
uniform mat4 matProjection;

void main()
{
    vec4 worldPosition = instanceTransform * vec4(vertexPosition, 1.0);
    gl_Position = matProjection * matView * worldPosition;

    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor * instanceColor;

    mat3 normalMatrix = mat3(transpose(inverse(instanceTransform)));
    fragNormal = normalize(normalMatrix * vertexNormal);

    fragPosition = worldPosition.xyz;
}
