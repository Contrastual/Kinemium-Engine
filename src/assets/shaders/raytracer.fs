#version 330

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0;  // Scene texture
uniform vec2 resolution;
uniform float time;
uniform vec3 cameraPos;
uniform vec3 cameraTarget;
uniform float cameraFov;

// Constants
#define PI 3.14159265359
#define MAX_BOUNCES 3
#define EPSILON 0.001
#define MAX_DIST 100.0

// Materials
#define MAT_DIFFUSE 0
#define MAT_METAL 1
#define MAT_GLASS 2

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Material {
    int type;
    vec3 albedo;
    float roughness;
    float metallic;
    float ior;
};

struct HitRecord {
    bool hit;
    float t;
    vec3 point;
    vec3 normal;
    Material material;
};

struct Light {
    vec3 position;
    vec3 color;
    float intensity;
    float radius;
};

// Define your lights
Light lights[2];

void initLights() {
    lights[0].position = vec3(3.0, 5.0, 2.0);
    lights[0].color = vec3(1.0, 0.95, 0.9);
    lights[0].intensity = 50.0;
    lights[0].radius = 0.5;
    
    lights[1].position = vec3(-4.0, 3.0, -2.0);
    lights[1].color = vec3(0.9, 0.95, 1.0);
    lights[1].intensity = 20.0;
    lights[1].radius = 0.3;
}

// Random number generation
uint seed = 0u;

uint hash(uint x) {
    x += (x << 10u);
    x ^= (x >> 6u);
    x += (x << 3u);
    x ^= (x >> 11u);
    x += (x << 15u);
    return x;
}

void initRandom(vec2 uv) {
    seed = hash(uint(uv.x * 1973.0 + uv.y * 9277.0 + time * 26699.0)) | 1u;
}

float random() {
    seed = hash(seed);
    return float(seed) / 4294967296.0;
}

vec3 randomUnitVector() {
    float z = random() * 2.0 - 1.0;
    float a = random() * 2.0 * PI;
    float r = sqrt(1.0 - z * z);
    return vec3(r * cos(a), r * sin(a), z);
}

// Fresnel
float schlick(float cosine, float ior) {
    float r0 = (1.0 - ior) / (1.0 + ior);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow(1.0 - cosine, 5.0);
}

// Sphere intersection
HitRecord hitSphere(Ray ray, vec3 center, float radius, Material mat) {
    HitRecord rec;
    rec.hit = false;
    
    vec3 oc = ray.origin - center;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - 4.0 * a * c;
    
    if (discriminant > 0.0) {
        float t = (-b - sqrt(discriminant)) / (2.0 * a);
        if (t > EPSILON && t < MAX_DIST) {
            rec.hit = true;
            rec.t = t;
            rec.point = ray.origin + ray.direction * t;
            rec.normal = normalize(rec.point - center);
            rec.material = mat;
        }
    }
    
    return rec;
}

// Plane intersection
HitRecord hitPlane(Ray ray, vec3 point, vec3 normal, Material mat) {
    HitRecord rec;
    rec.hit = false;
    
    float denom = dot(normal, ray.direction);
    if (abs(denom) > EPSILON) {
        float t = dot(point - ray.origin, normal) / denom;
        if (t > EPSILON && t < MAX_DIST) {
            rec.hit = true;
            rec.t = t;
            rec.point = ray.origin + ray.direction * t;
            rec.normal = normal;
            rec.material = mat;
        }
    }
    
    return rec;
}

// Scene
HitRecord intersectScene(Ray ray) {
    HitRecord closest;
    closest.hit = false;
    closest.t = MAX_DIST;
    
    Material mat;
    
    // Ground plane
    mat.type = MAT_DIFFUSE;
    mat.albedo = vec3(0.8);
    mat.roughness = 1.0;
    HitRecord hit = hitPlane(ray, vec3(0, 0, 0), vec3(0, 1, 0), mat);
    if (hit.hit && hit.t < closest.t) closest = hit;
    
    // Glass sphere
    mat.type = MAT_GLASS;
    mat.albedo = vec3(1.0);
    mat.ior = 1.5;
    hit = hitSphere(ray, vec3(0, 2, 0), 1.0, mat);
    if (hit.hit && hit.t < closest.t) closest = hit;
    
    // Metal sphere
    mat.type = MAT_METAL;
    mat.albedo = vec3(0.9);
    mat.roughness = 0.1;
    mat.metallic = 1.0;
    hit = hitSphere(ray, vec3(-3, 1.5, 0), 1.0, mat);
    if (hit.hit && hit.t < closest.t) closest = hit;
    
    // Red sphere
    mat.type = MAT_DIFFUSE;
    mat.albedo = vec3(0.9, 0.2, 0.2);
    hit = hitSphere(ray, vec3(3, 1.5, 0), 1.0, mat);
    if (hit.hit && hit.t < closest.t) closest = hit;
    
    return closest;
}

// Shadow test
bool isInShadow(vec3 point, vec3 lightPos) {
    vec3 toLight = lightPos - point;
    float lightDist = length(toLight);
    
    Ray shadowRay;
    shadowRay.origin = point + normalize(toLight) * EPSILON * 2.0;
    shadowRay.direction = normalize(toLight);
    
    HitRecord hit = intersectScene(shadowRay);
    return hit.hit && hit.t < lightDist;
}

// Lighting
vec3 calculateLighting(vec3 point, vec3 normal, vec3 viewDir, Material mat) {
    vec3 color = vec3(0.0);
    
    for (int i = 0; i < 2; i++) {
        if (isInShadow(point, lights[i].position)) continue;
        
        vec3 L = normalize(lights[i].position - point);
        float distance = length(lights[i].position - point);
        float attenuation = lights[i].intensity / (distance * distance);
        vec3 radiance = lights[i].color * attenuation;
        
        float NdotL = max(dot(normal, L), 0.0);
        color += mat.albedo * radiance * NdotL;
    }
    
    vec3 ambient = vec3(0.03) * mat.albedo;
    return color + ambient;
}

// Trace
vec3 trace(Ray ray) {
    vec3 color = vec3(0.0);
    vec3 throughput = vec3(1.0);
    
    for (int bounce = 0; bounce < MAX_BOUNCES; bounce++) {
        HitRecord rec = intersectScene(ray);
        
        if (!rec.hit) {
            float t = 0.5 * (ray.direction.y + 1.0);
            color += throughput * mix(vec3(1.0), vec3(0.5, 0.7, 1.0), t);
            break;
        }
        
        vec3 viewDir = -ray.direction;
        
        if (rec.material.type == MAT_GLASS) {
            float eta = dot(ray.direction, rec.normal) < 0.0 ? (1.0 / rec.material.ior) : rec.material.ior;
            vec3 normal = dot(ray.direction, rec.normal) < 0.0 ? rec.normal : -rec.normal;
            
            vec3 refracted = refract(ray.direction, normal, eta);
            
            if (length(refracted) > 0.0) {
                ray.origin = rec.point - normal * EPSILON;
                ray.direction = refracted;
                throughput *= rec.material.albedo;
            } else {
                ray.origin = rec.point + normal * EPSILON;
                ray.direction = reflect(ray.direction, normal);
            }
        }
        else if (rec.material.type == MAT_METAL && rec.material.roughness < 0.3) {
            vec3 reflected = reflect(ray.direction, rec.normal);
            ray.origin = rec.point + rec.normal * EPSILON;
            ray.direction = reflected;
            throughput *= rec.material.albedo;
        }
        else {
            vec3 lighting = calculateLighting(rec.point, rec.normal, viewDir, rec.material);
            color += throughput * lighting;
            break;
        }
    }
    
    return color;
}

void main() {
    initRandom(gl_FragCoord.xy);
    initLights();
    
    // Camera setup
    vec3 forward = normalize(cameraTarget - cameraPos);
    vec3 right = normalize(cross(forward, vec3(0, 1, 0)));
    vec3 up = cross(right, forward);
    
    float aspectRatio = resolution.x / resolution.y;
    float fovRad = cameraFov * PI / 180.0;
    float viewportHeight = 2.0 * tan(fovRad / 2.0);
    float viewportWidth = aspectRatio * viewportHeight;
    
    vec2 uv = gl_FragCoord.xy / resolution;
    vec2 ndc = uv * 2.0 - 1.0;
    
    vec3 rayDir = normalize(
        forward +
        right * ndc.x * viewportWidth * 0.5 +
        up * ndc.y * viewportHeight * 0.5
    );
    
    Ray ray;
    ray.origin = cameraPos;
    ray.direction = rayDir;
    
    vec3 color = trace(ray);
    
    // Tone mapping
    color = color / (color + 1.0);
    
    // Gamma correction
    color = pow(color, vec3(1.0 / 2.2));
    
    finalColor = vec4(color, 1.0);
}