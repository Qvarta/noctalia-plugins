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
    
    vec4 originalImage = texture(source, uv);
    
    float outerRadius = 0.5;      // внешний край синего круга
    float innerRadius = 0.4;     // внутренний край синего круга / внешний край белого
    
    // 1. Маска для синего кольца 
    float blueMask = (1.0 - smoothstep(innerRadius - 0.03, innerRadius, dist)) * 
                     (1.0 - smoothstep(outerRadius - 0.03, outerRadius, dist));
    
    // 2. Маска для внутреннего круга
    // Размытие на 0.05 единиц для плавного перехода
    float innerCircleMask = 1.0 - smoothstep(innerRadius - 0.05, innerRadius, dist);
    
    // 3. Эффект ряби для внутреннего круга
    float waveFreq = ub.waveFrequency > 0.0 ? ub.waveFrequency : 30.0;
    float waveAmp = ub.waveAmplitude > 0.0 ? ub.waveAmplitude : 0.015;
    float waveSpeed = ub.time * ub.speed * 1.5;
    
    float ripple = sin(dist * waveFreq - waveSpeed) * waveAmp;
    float falloff = 1.0 - smoothstep(0.1, innerRadius - 0.05, dist);
    ripple = ripple * falloff;
    
    // Искажаем UV координаты для эффекта ряби
    vec2 distortedUv = uv + centered * ripple;
    vec4 innerImage = texture(source, distortedUv);
    
    // Тени и блики для ряби
    vec2 shadowOffset = centered * ripple * 1.2;
    vec2 shadowUv = uv + shadowOffset;
    vec4 shadowColor = texture(source, shadowUv);
    
    float shadowIntensity = abs(ripple) * 1.5;
    vec3 imageWithRipple = mix(innerImage.rgb, shadowColor.rgb * 0.3, shadowIntensity);
    
    float highlight = max(0.0, sin(dist * waveFreq - waveSpeed) * 0.5 + 0.5) * ripple * 5.0;
    imageWithRipple += vec3(highlight * 0.5, highlight * 0.3, highlight);
    
    // 4. Цвета
    vec3 blueColor = vec3(0.1, 0.2, 0.8);
    vec3 whiteColor = vec3(1.0, 1.0, 1.0);
    
    // 5. Смешиваем слои
    vec3 finalColor = blueColor * blueMask;
    vec3 whiteLayer = whiteColor * innerCircleMask;
    finalColor = mix(finalColor, whiteLayer, innerCircleMask);
    vec3 imageLayer = imageWithRipple * innerCircleMask;
    finalColor = mix(finalColor, imageLayer, innerCircleMask);
    
    float finalAlpha = 1.0 - smoothstep(outerRadius - 0.05, outerRadius + 0.05, dist);
    
    fragColor = vec4(finalColor, finalAlpha);
}