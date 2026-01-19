#version 330 core

in vec2 vTexCoord;

uniform sampler2D uScene;

out vec4 FragColor;

void main()
{
    vec4 color = texture(uScene, vTexCoord);
    FragColor = vec4(color.r, 0.0, 0.0, color.a * 0.5);
}