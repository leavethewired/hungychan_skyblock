#version 120

#include "/settings.glsl"

in vec2 TexCoords;

uniform int isEyeInWater;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

uniform float near, far;
uniform float blindness;
uniform float darknessFactor;
uniform float rainStrength;
uniform vec3 fogColor;
uniform int worldTime;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
	vec4 homPos = projectionMatrix * vec4(position, 1.0);
	return homPos.xyz / homPos.w;
}

float FogExp2(float viewDistance, float density) {
    float factor = viewDistance * (density / sqrt(log(2.0f)));
    return exp(-factor * factor);
}

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

float state;

void main() {
	vec3 color = texture2D(colortex0, TexCoords).rgb;
	
	state = smoothTransition(worldTime);
	
	vec3 albedoOld = color;
	float depth0 = texture2D(depthtex0, TexCoords).r;

	vec3 NDCPos = vec3(TexCoords.xy, depth0) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	
	float farW = far;
	float distW = FOG_DISTANCE;
	
	if(isEyeInWater == 1) {
		farW = 64;
		distW = 5;
	}
	
	float distance = length(viewPos) / (farW * mix(mix(1, near * 0.5, blindness), near, darknessFactor));
	float fogFactor = 1 - clamp(FogExp2(distance, distW), 0.0f, 1.0f);
	
	vec3 fog_color = fogColor;
	float average = (fog_color.r + fog_color.g + fog_color.b) / 3.0;
	fog_color = mix(vec3(average), fog_color, 0.35);
	
	vec3 redTone = vec3(1.0, 0.2, 0.2);
	#if RED_FILTER == 1
	fog_color = mix(fog_color, redTone, 0.3 * state * (1 - rainStrength) * (1 - blindness));
	#endif
	fog_color = mix(fog_color, vec3(0.5), 0.25 * state * rainStrength);
	
	color = mix(color, pow(fog_color, vec3(2.2f)), clamp(fogFactor, 0.0, 1.0));
	
	if (depth0 == 1.0f) {
        color = mix(albedoOld, color, rainStrength);
    }
	
	/*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color, 1.0f);
}
