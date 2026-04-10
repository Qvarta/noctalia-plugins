#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;

    vec2 resolution;
    vec4 bgColor1;
    vec4 bgColor2;
    float size;
    vec2 center;
} ubuf;

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
    uv.x *= aspect;

    float size = ubuf.size > 0.0 ? ubuf.size : 0.3;
    float baseRadius = ubuf.size > 0.0 ? ubuf.size : 0.08;
    vec2 squareCenter = ubuf.center;

    if(squareCenter.x == 0.0 && squareCenter.y == 0.0) {
        squareCenter = vec2(0.5);
    }

    // ========== АНИМАЦИЯ: КРУГ ВРАЩАЕТСЯ ВОКРУГ КВАДРАТА ==========
    float timeSec = ubuf.time;

    // Параметры орбиты
    float orbitRadius = 0.2;      // Радиус орбиты
    float orbitSpeed = 0.3;        // Скорость вращения

    // Вычисляем позицию круга на орбите
    vec2 circleCenter = squareCenter;
    circleCenter.x += cos(timeSec * orbitSpeed) * orbitRadius;
    circleCenter.y += sin(timeSec * orbitSpeed) * orbitRadius;

    // Пульсация радиуса круга
    float pulse = 0.7 + 0.3 * sin(timeSec / 2.0);
    float animatedRadius = baseRadius * pulse / 6;

    // Квадрат (статичный)
    float left = squareCenter.x - size / 2.0;
    float right = squareCenter.x + size / 2.0;
    float bottom = squareCenter.y - size / 2.0;
    float top = squareCenter.y + size / 2.0;

    bool inSquare = (uv.x >= left && uv.x <= right &&
        uv.y >= bottom && uv.y <= top);

    // Круг (движущийся)
    float distToCircleCenter = distance(uv, circleCenter);
    bool inCircle = (distToCircleCenter <= animatedRadius);

    // Результат
    vec4 color = vec4(0.0);

    if(inSquare) {
        color = ubuf.bgColor1;
    }

    if(inCircle) {
        color = ubuf.bgColor2;
    }

    fragColor = color;
}