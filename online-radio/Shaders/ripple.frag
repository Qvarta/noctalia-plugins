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
} ub;

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    
    // Создаем маску круга (радиус 0.5, так как квадрат от 0 до 1)
    float circleMask = 1.0 - smoothstep(0.48, 0.5, dist);
    
    // Если пиксель вне круга - делаем его прозрачным
    if (circleMask <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // uniform-переменные
    float waveFreq = ub.waveFrequency > 0.0 ? ub.waveFrequency : 30.0;
    float waveAmp = ub.waveAmplitude > 0.0 ? ub.waveAmplitude : 0.015;
    float waveSpeed = ub.time * ub.speed * 1.5;
    
    float ripple = sin(dist * waveFreq - waveSpeed) * waveAmp;
    float falloff = 1.0 - smoothstep(0.1, 0.8, dist);
    ripple = ripple * falloff;
    
    vec2 distortedUv = uv + centered * ripple;
    vec4 color = texture(source, distortedUv);
    
    vec2 shadowOffset = centered * ripple * 1.2;
    vec2 shadowUv = uv + shadowOffset;
    vec4 shadowColor = texture(source, shadowUv);
    
    float shadowIntensity = abs(ripple) * 1.5;
    
    vec3 finalColor = mix(color.rgb, shadowColor.rgb * 0.3, shadowIntensity);
    
    float highlight = max(0.0, sin(dist * waveFreq - waveSpeed) * 0.5 + 0.5) * ripple * 5.0;
    finalColor += vec3(highlight * 0.5, highlight * 0.3, highlight);
    
    fragColor = vec4(finalColor, color.a * circleMask);
}