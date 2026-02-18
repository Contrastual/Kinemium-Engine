#version 330

in vec3 vertexPosition;
in vec3 vertexNormal;
in vec2 vertexTexCoord;
in vec4 vertexColor;

uniform mat4 matModel;
uniform mat4 matView;
uniform mat4 matProjection;
uniform mat4 matNormal;
uniform mat4 lightSpaceMatrix;

out vec3 vNormal;
out vec3 vWorldPos;
out vec2 vTexCoord;
out vec4 vColor;
out vec4 vLightSpacePos;

void main()
{
    vec4 worldPos = matModel * vec4(vertexPosition, 1.0);
    vWorldPos = worldPos.xyz;
    vNormal = normalize((matNormal * vec4(vertexNormal, 0.0)).xyz);
    vTexCoord = vertexTexCoord;
    vColor = vertexColor;
    vLightSpacePos = lightSpaceMatrix * worldPos;

    gl_Position = matProjection * matView * worldPos;
}
