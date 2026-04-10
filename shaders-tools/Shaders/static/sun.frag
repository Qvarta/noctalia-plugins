#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 bgColor;
    vec2 resolution;
} ubuf;

void main() {
    // Преобразуем координаты в диапазон -1..1
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    
    // Исправляем соотношение сторон (компенсируем ширину экрана)
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
     uv.x *= aspect;
    
    vec3 color = ubuf.bgColor.rgb;;

    float d = length(uv);
    d = 0.4/d;
    // color *= d;
    color *= smoothstep(0.5, 0.8, d);
    fragColor = vec4(color, 1);
}