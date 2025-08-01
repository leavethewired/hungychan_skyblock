#version 120

#include "/settings.glsl"

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;

uniform sampler2D texture;
uniform float rainStrength;

uniform int worldTime;

float state;

float smoothTransition(float time) {
    if (time >= 0.0f && time <= 1000.0f) {
        return time / 1000.0f; // Transition from 0 to 1
    } else if (time > 1000.0f && time < 12000.0f) {
        return 1.0f; // Fully enabled
    } else if (time >= 12000.0f && time <= 13000.0f) {
        return 1.0f - (time - 12000.0f) / 1000.0f; // Transition from 1 to 0
    } else {
        return 0.0f; // Fully disabled
    }
}

void main()
{
	vec3 ac = vec3(0.8, 0.85, 0.95);
	vec3 albedo = texture2D(texture, TexCoords).rgb * Color.rgb * ac;

	state = smoothTransition(worldTime);

	// Add red tone (blending more red into the final color)
	vec3 redTone = vec3(1.0, 0.2, 0.2);  // Red-tinted color
	albedo = mix(albedo, redTone, 0.25 * state * (1 - rainStrength));  // Adjust the blending factor for intensity
	
	float alpha = 0.0f;
	
	#if CLOUDS == 1
	alpha = 1.0f;
	#endif
	#if CLOUDS == 2
	alpha = 1.0f * state;
	#endif
	
	/* DRAWBUFFERS:012 */
    gl_FragData[0] = vec4(albedo, alpha);
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}
