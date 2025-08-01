#version 130

#include "/settings.glsl"

varying vec2 TexCoords;
uniform float viewWidth, viewHeight;
uniform int worldTime;
uniform sampler2D colortex0;
uniform sampler2D colortex5;

#if AUTO_EXPOSURE == 1
const bool colortex5Clear = false;
const bool colortex0MipmapEnabled = true;
#endif

float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;

float state;

float smoothTransition(float time) {
    if (time >= 0.0f && time <= 1000.0f) {
        return time / 1000.0f;
	} else if (time > 1000.0f && time < 12000.0f) {
        return 1.0f;
    } else if (time >= 12000.0f && time <= 13000.0f) {
        return 1.0f - (time - 12000.0f) / 1000.0f;
    } else {
        return 0.0f;
    }
}

void AutoExposure(inout vec3 color, inout float exposure, float tempExposure) {
	float exposureLod = log2(viewHeight * AUTO_EXPOSURE_RADIUS);
	
	exposure = length(texture2DLod(colortex0, vec2(0.5), exposureLod).rgb);
	exposure = max(exposure, 0.0001);
	
	color /= tempExposure + 0.125;
}

void Tonemap(inout vec3 color) {
	color *= exp2(1.5 + EXPOSURE);

	color = color / vec3(TONEMAP_WHITE), vec3(1.0 / TONEMAP_WHITE);

	color = clamp(color, vec3(0.0), vec3(1.0));
}

void main() {
	vec3 color = texture2D(colortex0, TexCoords).rgb;
	vec3 mixColor = color;
	
	#if AUTO_EXPOSURE == 1
	float tempExposure = texture2D(colortex5, vec2(pw, ph)).r;
    #endif
	
	vec3 temporalColor = vec3(0.0);

    #if AUTO_EXPOSURE == 1
	float exposure = 1.0;
	AutoExposure(color, exposure, tempExposure);
    #endif
	
	Tonemap(color);
	
	float temporalData = 0.0;
	
	#if AUTO_EXPOSURE == 1
	if (TexCoords.x < 2.0 * pw && TexCoords.y < 2.0 * ph)
		temporalData = mix(tempExposure, sqrt(exposure), AUTO_EXPOSURE_SPEED);
	#endif
	
	//state = smoothTransition(worldTime);
	//color = vec3((color * state) + (mixColor * (1 - state)));
	
	/* DRAWBUFFERS:45 */
	gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(temporalData, temporalColor);
}
