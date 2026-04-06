#version 440

layout(location = 0) in vec2 qt_TexCoord0;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;      // Матрица Qt 
    float qt_Opacity;    // Прозрачность от Qt 
    float time;          // Время из QML
    float speed;         // Скорость смены оттенков
} ub;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float radius = length(uv);
    
    if (radius > 1.0) discard;

    float hue = 0.25 + fract(ub.time * ub.speed * 0.05) * 0.2;
    float saturation = 0.8 + sin(ub.time * ub.speed * 1.5) * 0.2;
    float value = 0.7 + sin(ub.time * ub.speed * 2.0) * 0.2;
    
    vec3 hsvColor = vec3(hue, saturation, value);
    vec3 color = hsv2rgb(hsvColor);
    
    float alpha = (1.0 - smoothstep(0.95, 1.0, radius)) * 0.85;
    
    fragColor = vec4(color, alpha);
}