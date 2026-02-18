#version 330

in vec2 fragTexCoord;
in vec3 fragNormal;
in vec3 fragPosition;
in vec4 fragPosLightSpace;

uniform sampler2D texture0;
uniform sampler2D shadowMap;

uniform vec4 colDiffuse;
uniform vec3 lightPos;
uniform vec3 viewPos;

out vec4 finalColor;

float Hash12(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float ShadowCalculation(vec4 fragPosLightSpace, vec3 normal, vec3 lightDir)
{
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5;

    if (projCoords.z > 1.0 || projCoords.x < 0.0 || projCoords.x > 1.0 || projCoords.y < 0.0 || projCoords.y > 1.0)
        return 0.0;

    float sunHeight = clamp(lightDir.y, 0.0, 1.0);
    float dayFactor = smoothstep(0.02, 0.18, sunHeight);

    float currentDepth = projCoords.z;

    float bias = max(0.04 * (1.0 - dot(normal, lightDir)), 0.003);
    bias *= mix(2.2, 1.0, sunHeight);

    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    float softness = mix(2.2, 0.9, sunHeight);
    vec2 jitter = vec2(Hash12(gl_FragCoord.xy), Hash12(gl_FragCoord.yx)) - 0.5;
    for(int x = -1; x <= 1; ++x)
    {
        for(int y = -1; y <= 1; ++y)
        {
            vec2 offset = (vec2(x, y) + jitter) * texelSize * softness;
            float pcfDepth = texture(shadowMap, projCoords.xy + offset).r;
            shadow += currentDepth - bias > pcfDepth ? 1.0 : 0.0;
        }
    }
    shadow /= 9.0;
    shadow *= dayFactor;

    return shadow;
}

void main()
{
    vec3 color = texture(texture0, fragTexCoord).rgb * colDiffuse.rgb;
    vec3 normal = normalize(fragNormal);

    vec3 ambient = 0.3 * color;

    vec3 lightDir = normalize(lightPos - fragPosition);
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * color;

    vec3 viewDir = normalize(viewPos - fragPosition);
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), 64.0);
    vec3 specular = spec * vec3(0.3);

    float shadow = ShadowCalculation(fragPosLightSpace, normal, lightDir);

    vec3 lighting = (ambient + (1.0 - shadow) * (diffuse + specular));

    finalColor = vec4(lighting, 1.0);
}
