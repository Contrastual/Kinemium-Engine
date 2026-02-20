#version 330

// Vertex attributes
in vec3 vertexPosition;
in vec3 vertexNormal;
in vec2 vertexTexCoord;
in vec4 vertexColor;

// Instance attributes (mat4 uses 4 consecutive locations)
in mat4 instanceMatrix;

uniform mat4 matView;
uniform mat4 matProjection;
uniform mat4 lightSpaceMatrix;

out vec3 vNormal;
out vec3 vWorldPos;
out vec2 vTexCoord;
out vec4 vColor;
out vec4 vLightSpacePos;

void main()
{
    // Use instance matrix for per-object transformation
    vec4 worldPos = instanceMatrix * vec4(vertexPosition, 1.0);
    vWorldPos = worldPos.xyz;
    
    // Normal matrix: inverse transpose of upper-left 3x3
    mat3 normalMat = mat3(instanceMatrix);
    vNormal = normalize(normalMat * vertexNormal);
    
    vTexCoord = vertexTexCoord;
    vColor = vertexColor;
    vLightSpacePos = lightSpaceMatrix * worldPos;

    gl_Position = matProjection * matView * worldPos;
}
