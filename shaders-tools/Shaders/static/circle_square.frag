#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 bgColor;
    vec4 bgColor1;
    vec4 bgColor2;
    vec2 resolution;
    float size;
} ubuf;

float circleAlpha(vec2 uv, float radius) {
    return length(uv) < radius ? 1.0 : 0.0;
}

float squareAlpha(vec2 uv, float size) {
    float halfSize = size / 2.0;
    return (abs(uv.x) < halfSize && abs(uv.y) < halfSize) ? 1.0 : 0.0;
}

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
    uv.x *= aspect;

    float alphaC = circleAlpha(uv, ubuf.size);
    float alphaS = squareAlpha(uv, ubuf.size);

    // vec4 colorC = alphaC * ubuf.bgColor1;
    // vec4 colorS = alphaS * ubuf.bgColor2;  

        // Плавно меняем цвет круга между bgColor1 и bgColor2
    float t = 0.5 + 0.5 * sin(ubuf.time * 0.8);  // 0..1
    vec4 animatedColor = mix(ubuf.bgColor1, ubuf.bgColor2, t);

    vec4 colorC = alphaC * animatedColor;
    vec4 colorS = alphaS * ubuf.bgColor2;

    fragColor = colorC + colorS;
}