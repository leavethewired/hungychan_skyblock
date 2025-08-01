#version 120

#include "/settings.glsl"

in vec2 TexCoords;
in vec2 LightmapCoords;
in vec3 Color;
in vec3 Normal;
in float blockId;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform float frameTimeCounter;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

uniform float rainStrength;
uniform int worldTime;
float state;

vec2 encode (vec3 n){
    return vec2(n.xy * inversesqrt(n.z * 8.0 + 8.0) + 0.5);
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

void main(){
    vec4 outputColorData = texture2D(texture, TexCoords);
	vec3 albedo = outputColorData.rgb * Color;
	
	state = smoothTransition(worldTime);
	
	vec3 redTone = vec3(1.0, 0.2, 0.2);  // Red-tinted color
	#if RED_FILTER == 1
	albedo.rgb = mix(albedo.rgb, redTone, 0.25 * state * (1 - rainStrength));  // Adjust the blending factor for intensity
	#endif

	vec3 norm = Normal;
	float diffuseLight = 0.25;
	vec2 normalssr = vec2(0.001f);
	vec3 shadowLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
	
	if (int(blockId + 0.5) == 1000) {
		outputColorData.a = 0.9f;
        diffuseLight = clamp(dot(shadowLightDir, Normal), 0.0f, 1.0f);
		
		#if SSR == 1
		vec4 noiseSample = texture2D(noisetex, (TexCoords + vec2(0.1, 0.2) + vec2(sin(frameTimeCounter), cos(frameTimeCounter)) * 0.0005) * 32); // 512
		vec3 noiseEffect = noiseSample.rgb * 0.025;
		norm += noiseEffect;
		norm = normalize(norm);
		normalssr = encode(norm);
		#else
		normalssr.x = 1.0f;
		#endif
    }
	
    /* DRAWBUFFERS:023 */
    gl_FragData[0] = vec4(albedo, outputColorData.a);
    gl_FragData[1] = vec4(LightmapCoords, diffuseLight, outputColorData.a);
	gl_FragData[2] = vec4(normalssr, vec2(1.0f));
}
