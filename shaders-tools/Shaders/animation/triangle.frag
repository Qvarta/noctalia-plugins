
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 bgColor1;
    vec4 bgColor2;
    vec2 resolution;
    float size;
} ubuf;

float sdEquilateralTriangle(in vec2 p, in float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if(p.x + k * p.y > 0.0)
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
    uv.x *= aspect;

   //Движение по X от -1.0 до 1.0
    float moveX = sin(ubuf.time * 0.05) * 1.0;
    uv.x -= moveX;

    //Движение по Y от -1.0 до 1.0
    float moveY = cos(ubuf.time * 0.1) * 1.0;
    uv.y -= moveY;

    // Пульсация
    float pulse = 0.8 + 0.4 * abs(sin(ubuf.time * 0.25));
    float animatedRadius = ubuf.size * pulse;

    // микс цветов ( / 7.0 - меньше цикл смены)
    float mixFactor = (sin(ubuf.time * 0.05) + 1.0) / 2.0;
    vec3 color = mix(ubuf.bgColor1.xyz, ubuf.bgColor2.xyz, mixFactor);

    float d = sdEquilateralTriangle(uv, animatedRadius);

    fragColor = d < 0.0 ? vec4(color, 1) : vec4(0.0);
}