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

// Функция возвращает цвет кольца (или vec4(0.0) если вне кольца)
vec4 drawRing(vec2 uv, float innerRadius, float outerRadius, float blur, vec3 color1, vec3 color2) {
    float d = length(uv);

    // Альфа для кольца
    float alpha = exp(-pow((d - outerRadius) / blur, 2.0)) *
        (1.0 - exp(-pow((d - innerRadius) / (blur * 0.5), 2.0)));

    alpha = step(0.05, alpha);

    if(alpha < 0.5) {
        return vec4(0.0);
    }

    vec3 color = color1;
    color += color2 * exp(-pow((d - outerRadius) / (blur * 0.3), 2.0));

    return vec4(color, 1.0);
}

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
    uv.x *= aspect;

    float innerRadius = 0.43;
    float outerRadius = 0.45;
    float blur = 0.01;

    vec3 color1 = vec3(0.6, 0.3, 0.9);
    vec3 color2 = vec3(0.8, 0.4, 1.0);

    fragColor = drawRing(uv, innerRadius, outerRadius, blur, color1, color2);
}