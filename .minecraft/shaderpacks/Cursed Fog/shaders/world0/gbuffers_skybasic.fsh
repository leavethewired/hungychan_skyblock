#version 120

#include "/settings.glsl"

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int worldTime;

uniform float rainStrength;
uniform int isEyeInWater;
uniform sampler2D texture;

in vec2 TexCoords;
in vec2 LightmapCoords;
in vec3 Normal;
in vec4 Color;
in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

float state;

float fogify(float x, float w) {
	return w / (x * x + w);
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

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz);
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
}

void main()
{
	vec3 color;
	if (starData.a > 0.5) {
		color = starData.rgb * 0.65;
	}
	else {
		vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
		pos = gbufferProjectionInverse * pos;
		color = calcSkyColor(normalize(pos.xyz));
		
		state = smoothTransition(worldTime);
		
		float average = (color.r + color.g + color.b) / 3.0;
		color = mix(vec3(average), color, 0.35);
		
		vec3 redTone = vec3(1.0, 0.2, 0.2);
		#if RED_FILTER == 1
		color = mix(color, redTone, 0.3 * state * (1 - rainStrength));
		#endif
		
		color = mix(color, vec3(0.5), 0.25 * state * rainStrength);
	}
	
	if(gl_Fog.color.rgb == vec3(0.0f))
	{
		color = vec3(0.0f);
	}
	
	/* DRAWBUFFERS:02 */
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(1.0f);
}
