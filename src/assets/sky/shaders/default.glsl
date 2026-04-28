void fragment() {
    vec3 ro = POSITION;
    vec3 rd = normalize(EYEDIR);

    vec3 sunDir = normalize(vec3(0.3, 1, -1.0));
    float sunDot = dot(rd, sunDir);

    float t = max(rd.y, 0.0);
    vec3 zenith  = vec3(0.08, 0.18, 0.55);
    vec3 horizon = vec3(0.60, 0.75, 0.90);
    vec3 sky = mix(horizon, zenith, pow(t, 0.45));

    float haze = pow(1.0 - abs(rd.y), 5.0);
    sky += vec3(0.25, 0.22, 0.15) * haze;

    float sunDisk = smoothstep(0.9994, 0.9997, sunDot);
    sky = mix(sky, vec3(1.5, 1.3, 0.9), sunDisk);

    float corona = pow(max(sunDot, 0.0), 128.0);
    sky += vec3(0.9, 0.7, 0.35) * corona * 0.6;

    float scatter = pow(max(sunDot, 0.0), 6.0) * (1.0 - t);
    sky += vec3(0.8, 0.4, 0.1) * scatter * 0.5;

    if (rd.y < 0.0) {
        float below = pow(max(-rd.y, 0.0), 0.3);
        sky = mix(sky, vec3(0.15, 0.12, 0.10), below);
    }

    COLOR = sky;
}