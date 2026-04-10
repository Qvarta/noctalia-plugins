#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float speed;
    float waveFrequency;
    float waveAmplitude;
    vec3 fireColor;        
    float fireIntensity;   
} ub;

layout(binding = 1) uniform sampler2D source;

#define M_PI 3.1415926535897932384626433832795
#define M_TWO_PI (2.0 * M_PI)

// ============================================================
// НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ
// ============================================================

// Параметры огненного кольца
const float FIRE_TUNNEL_DEPTH = 0.8;   // Глубина туннеля
const float FIRE_SPEED = 0.8;          // Скорость анимации огня
const float FIRE_BRIGHTNESS = 1.6;     // Яркость огня

// Параметры кругов
const float INNER_RADIUS = 0.45;        // Радиус внутреннего круга 
const float OUTER_RADIUS = 0.9;         // Внешний радиус огненного кольца
const float BLUR_ZONE = 0.1;           // Зона размытия границ

// Параметры ряби
const float RIPPLE_FALLOFF_START = 0.1; // Начало затухания ряби
const float SHADOW_INTENSITY = 1.5;     // Интенсивность тени
const float HIGHLIGHT_MULTIPLIER = 5.0; // Множитель бликов


// ============================================================
// ФУНКЦИИ ОГНЕННОГО ТУННЕЛЯ
// ============================================================

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 12.1414))) * 83758.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n);
    vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), 
               mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

vec3 ramp(float t) {
    vec3 fireColorRamp = ub.fireColor;
    if (fireColorRamp.r == 0.0 && fireColorRamp.g == 0.0 && fireColorRamp.b == 0.0) {
        fireColorRamp = vec3(2.0, 0.8, 0.2);
    }
    return fireColorRamp / (t + 0.1);
}

vec2 polarMap(vec2 uv, float shift, float inner) {
    uv = vec2(0.5) - uv;
    float px = 1.0 - fract(atan(uv.y, uv.x) / M_TWO_PI + 0.25) + shift;
    float py = (length(uv) * (1.0 + inner * 2.0) - inner) * 2.0;
    return vec2(px, py);
}

float fire(vec2 n) {
    return noise(n) + noise(n * 2.1) * 0.6 + noise(n * 5.4) * 0.42;
}

float shade(vec2 uv, float t) {
    uv.x += uv.y < 0.5 ? 23.0 + t * 0.035 : -11.0 + t * 0.03;
    uv.y = abs(uv.y - 0.5);
    uv.x *= 35.0;
    
    float q = fire(uv - t * 0.013) / 2.0;
    vec2 r = vec2(fire(uv + q / 2.0 + t - uv.x - uv.y), 
                  fire(uv + q - t));
    
    return pow((r.y * 2.0) * max(0.0, uv.y) + 0.1, 4.0);
}

vec3 getFireColor(float grad) {
    float intensity = ub.fireIntensity > 0.0 ? ub.fireIntensity : 0.3;
    float m2 = 1.15 * intensity;
    grad = sqrt(grad);
    vec3 color = ramp(grad);
    color /= (m2 + max(vec3(0.0), color));
    return color;
}

vec3 getFireTunnel(vec2 uv, float time) {
    float m1 = 3.6 * FIRE_TUNNEL_DEPTH;
    
    vec2 fireUv = uv;
    fireUv -= 0.5;
    fireUv *= 1.2;
    fireUv += 0.5;
    
    float ff = 1.0 - fireUv.y;
    vec2 uv2 = fireUv;
    uv2.y = 1.0 - uv2.y;
    
    vec2 polarUv = polarMap(fireUv, 1.3, m1);
    vec2 polarUv2 = polarMap(uv2, 1.9, m1);
    
    vec3 c1 = getFireColor(shade(polarUv, time)) * ff;
    vec3 c2 = getFireColor(shade(polarUv2, time)) * (1.0 - ff);
    
    return (c1 + c2) * FIRE_BRIGHTNESS;
}

// ============================================================
// ФУНКЦИИ РЯБИ НА ИЗОБРАЖЕНИИ
// ============================================================

float getRipple(float dist, float innerRadius, float time, float freq, float amp) {
    float speed = time * ub.speed * 1.5;
    float ripple = sin(dist * freq - speed) * amp;
    float falloff = 1.0 - smoothstep(RIPPLE_FALLOFF_START, innerRadius - 0.05, dist);
    return ripple * falloff;
}

vec3 applyRippleEffect(vec2 uv, vec2 centered, float ripple, float dist, float time, float freq) {
    // Искажённое изображение
    vec2 distortedUv = uv + centered * ripple;
    vec4 mainImage = texture(source, distortedUv);
    
    // Тени
    vec2 shadowUv = uv + centered * ripple * 1.2;
    vec4 shadowImage = texture(source, shadowUv);
    
    float shadowIntensity = abs(ripple) * SHADOW_INTENSITY;
    vec3 result = mix(mainImage.rgb, shadowImage.rgb * 0.3, shadowIntensity);
    
    // Блики
    float waveSpeed = time * ub.speed * 1.5;
    float highlight = max(0.0, sin(dist * freq - waveSpeed) * 0.5 + 0.5) * ripple * HIGHLIGHT_MULTIPLIER;
    result += vec3(highlight * 0.5, highlight * 0.3, highlight);
    
    return result;
}

// ============================================================
// ФУНКЦИИ МАСОК И СМЕШИВАНИЯ
// ============================================================

float getInnerCircleMask(float dist, float radius, float blur) {
    return 1.0 - smoothstep(radius - blur, radius, dist);
}

float getAlpha(float dist, float outerRadius, float blur) {
    return 1.0 - smoothstep(outerRadius - blur, outerRadius + blur, dist);
}

// ============================================================
// MAIN
// ============================================================

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    
    float innerMask = getInnerCircleMask(dist, INNER_RADIUS, BLUR_ZONE);
    float alpha = getAlpha(dist, OUTER_RADIUS, BLUR_ZONE);
    
    float waveFreq = ub.waveFrequency > 0.0 ? ub.waveFrequency : 30.0;
    float waveAmp = ub.waveAmplitude > 0.0 ? ub.waveAmplitude : 0.015;
    
    float ripple = getRipple(dist, INNER_RADIUS, ub.time, waveFreq, waveAmp);
    vec3 imageWithRipple = applyRippleEffect(uv, centered, ripple, dist, ub.time, waveFreq);
    
    // Огненное кольцо
    float fireTime = ub.time * ub.speed * FIRE_SPEED;
    vec3 fireColor = getFireTunnel(uv, fireTime);
    
    vec3 finalColor = fireColor;
    finalColor = mix(finalColor, imageWithRipple, innerMask);
    
    fragColor = vec4(finalColor, alpha * ub.qt_Opacity);
}