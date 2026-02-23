#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform float threshold;   // try 0.6
uniform float intensity;   // try 1.5
uniform float radius;      // try 6.0

out vec4 fragColor;

vec3 brightBlur(sampler2D tex, vec2 uv, float rad) {
    vec2 texelSize = 1.0 / vec2(textureSize(tex, 0));
    vec3 result = vec3(0.0);
    float totalWeight = 0.0;

    int samples = int(rad);
    for (int x = -samples; x <= samples; x++) {
        for (int y = -samples; y <= samples; y++) {
            float dist = sqrt(float(x * x + y * y));
            if (dist > rad) continue;

            float sigma = rad * 0.5;
            float weight = exp(-dist * dist / (2.0 * sigma * sigma));

            vec2 offset = vec2(float(x), float(y)) * texelSize * 2.0;
            vec3 col = texture(tex, uv + offset).rgb;

            float brightness = dot(col, vec3(0.2126, 0.7152, 0.0722));
            float extracted = max(brightness - threshold, 0.0) / (1.0 - threshold + 0.001);

            result += col * extracted * weight;
            totalWeight += weight;
        }
    }

    return totalWeight > 0.0 ? result / totalWeight : vec3(0.0);
}

void main() {
    vec3 original = texture(texture0, fragTexCoord).rgb;

    vec3 glow = brightBlur(texture0, fragTexCoord, radius);

    // Additive but controlled
    vec3 result = original + glow * intensity;

    // Stronger tonemapping to keep things from blowing out
    result = result / (result + vec3(1.0));

    fragColor = vec4(result, 1.0);
}