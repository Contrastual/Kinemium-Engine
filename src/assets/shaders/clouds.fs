// shaders/clouds.fs
#version 330

in vec2 fragTexCoord;
out vec4 fragColor;

uniform float time;
uniform vec2 resolution;

// Simple 2D hash
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Simple 2D noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fractal noise for cloud shape
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for(int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void main() {
    vec2 uv = fragTexCoord;
    
    // Animate clouds
    vec2 cloudUV = uv * 4.0; // Increased from 2.5 to 4.0 for smaller clouds
    cloudUV.x += time * 0.02;
    
    // Base cloud shape with varying frequencies for rounded appearance
    float clouds = fbm(cloudUV);
    
    // Add different scales for organic, rounded shapes
    clouds += fbm(cloudUV * 0.5) * 0.5;  // Large rounded forms
    clouds += fbm(cloudUV * 2.0) * 0.25; // Medium detail
    clouds += fbm(cloudUV * 4.0) * 0.15; // Fine detail
    
    // Smooth threshold for rounded edges
    clouds = smoothstep(0.5, 0.8, clouds);
    
    // Add wispy edges
    float wispiness = fbm(cloudUV * 6.0) * 0.3;
    clouds = smoothstep(0.3, 0.7, clouds + wispiness);
    
    // Pure white clouds - no shading
    vec3 cloudColor = vec3(1.0);
    
    // Output with transparency
    float alpha = pow(clouds, 1.5); // makes edges thinner
    fragColor = vec4(cloudColor, alpha * 0.5);
}