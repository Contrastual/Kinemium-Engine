#version 330

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec3 vertexNormal;

uniform mat4 mvp;
uniform mat4 matModel;

out vec3 fragPos;
out vec3 normal;

void main()
{
    fragPos = vec3(matModel * vec4(vertexPosition, 1.0));
    normal = mat3(transpose(inverse(matModel))) * vertexNormal;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
