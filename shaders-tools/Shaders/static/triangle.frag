
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 bgColor;
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
    float offsetX = 0.3;

    // Добавляем смещение по X
    // uv.x -= offsetX;  // или += в зависимости от направления

    float d = sdEquilateralTriangle(uv, ubuf.size);
    

    fragColor = d < 0.0 ? ubuf.bgColor : vec4(0.0);
}