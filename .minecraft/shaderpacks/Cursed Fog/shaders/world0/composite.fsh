#version 120

// Shader by LoLip_p

#include "distort.glsl"
#include "/settings.glsl"

varying vec2 TexCoords;

uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

// For Shadow
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

/*
const int colortex0Format = R11F_G11F_B10F;
const int colortex2Format = RGB8;
const int colortex3Format = RG16;
const int colortex5Format = R8;
*/

const int noiseTextureResolution = 64;

float state;

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - 0.0002f, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.0f - ShadowColor0.a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

const int ShadowSamplesPerSize = 2 * SOFT + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;

vec3 GetShadow(float depth) {
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
	
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
	
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xyz = DistortPosition(ShadowSpace.xyz);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
	
	SampleCoords = clamp(SampleCoords, 0.0, 1.0); // clamp
	
    float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; // We can move our division by the shadow map resolution here for a small speedup
    vec3 ShadowAccum = vec3(0.0f);
    for(int x = -SOFT; x <= SOFT; x++){
        for(int y = -SOFT; y <= SOFT; y++){
            vec2 Offset = Rotation * vec2(x, y);
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
			
			CurrentSampleCoordinate = clamp(CurrentSampleCoordinate, 0.0, 1.0); // clamp
			
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= TotalSamples;
    return ShadowAccum;
}

float AdjustLightmapTorch(in float torchLight) {
    const float K = 2.0f;
	const float P = 5.0f;
	
	#if FLICKERING_LIGHT == 0
	float sinMod = 1;
	#else
	float fastSin = sin(frameTimeCounter * 4);
    float slowSin = sin(frameTimeCounter * 2);
    float sinMod = 0.925 + 0.075 * (fastSin + slowSin) / 2.0;
	#endif
	
    return K * pow(torchLight * sinMod, P);
}

float AdjustLightmapSky(in float sky){
    float sky_2 = sky * sky;
    return sky_2 * sky_2;
}

vec2 AdjustLightmap(in vec2 Lightmap){
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);
    return NewLightMap;
}

vec3 GetLightmapColor(in vec2 Lightmap){
    Lightmap = AdjustLightmap(Lightmap);
	vec3 SkyColor = vec3(0.1f, 0.05f, 0.09f);
	
	#if ENABLE_SHADOW == 0
	SkyColor = vec3(1) * 0.1f;
	#endif
	
    vec3 TorchLighting = Lightmap.x * vec3(1.0f, 1.0f, 1.0f);
    vec3 SkyLighting = Lightmap.y * SkyColor * state * (1 - rainStrength);
	
	TorchLighting -= (Lightmap.y * LIGHT_ABSORPTION * state * (1 - rainStrength));
	
	vec3 LightmapLighting = clamp(TorchLighting * vec3(1.0f, 0.45f, 0.3f), 0.0f, 1.0f) + SkyLighting;
	
    return LightmapLighting;
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

float swapDayNight(float time) {
    if (time >= 12300.0f && time <= 12800.0f) {
        return (time - 12300.0f) / 500.0f; // Плавный переход от 0 до 1
    } else if (time > 12800.0f && time <= 13200.0f) {
        return 1.0f - (time - 12800.0f) / 500.0f; // Плавный переход от 1 до 0
    } else if (time >= 22700.0f && time <= 23200.0f) {
        return (time - 22700.0f) / 500.0f; // Плавный переход от 0 до 1
    } else if (time > 23200.0f && time <= 23700.0f) {
        return 1.0f - (time - 23200.0f) / 500.0f; // Плавный переход от 1 до 0
    } else {
        return 0.0f; // Вне указанных диапазонов
    }
}

void main(){
	vec3 Albedo = pow(texture2D(colortex0, TexCoords).rgb, vec3(2.2f));
	float normal = texture2D(colortex3, TexCoords).x;
	
	vec3 lightBrightnessV = vec3(0.1f);
    vec3 ShadowColor = vec3(1.0f);
	
	vec3 Lightmap = texture2D(colortex2, TexCoords).xyz;
	state = smoothTransition(worldTime);
	vec3 LightmapColor = GetLightmapColor(Lightmap.xy);
	
    float Depth = texture2D(depthtex0, TexCoords).r;
    if(Depth == 1.0f){
        gl_FragData[0] = vec4(Albedo, 1.0f);
        return;
    }

	#if SHADING == 1
	float lightBrightness = Lightmap.z;
	
	lightBrightness *= state;
	lightBrightness *= 1.0f - rainStrength;
	lightBrightness += (rainStrength - 0.5f) * (1.0f - state) * rainStrength; //Rain
	lightBrightnessV = vec3(lightBrightness) * state;
	lightBrightnessV += vec3(0.2, 0.2, 0.5) * (1.0f - state); //Night
	lightBrightnessV += SHADOW_TRANSPARENCY;
	#endif

	lightBrightnessV *= AdjustLightmap(Lightmap.xy).g;
	lightBrightnessV += 0.025f;
	
	if(normal > 0.002f) {
		#if ENABLE_SHADOW == 1
		vec3 originalShadow = GetShadow(Depth);
		float shadow_transperency_coef = mix(degree_night_darkness + 0.25f, SHADOW_TRANSPARENCY, state);
		ShadowColor = mix(originalShadow * vec3(shadow_transperency_coef / 0.75), originalShadow, state);
		ShadowColor = mix(ShadowColor, vec3(1), swapDayNight(worldTime));
		vec3 colorRainDayOrNight = mix(vec3(0.2), vec3(1), state);
		ShadowColor = mix(ShadowColor, colorRainDayOrNight, rainStrength);
		
		ShadowColor *= AdjustLightmap(Lightmap.xy).g;
		ShadowColor += shadow_transperency_coef;
		#endif
		
		LightmapColor *= mix(5, 1, state);
		
		Albedo *= clamp(state, SHADOW_TRANSPARENCY, 1.0f);
		Albedo *= (LightmapColor + lightBrightnessV * ShadowColor);
        gl_FragData[0] = vec4(Albedo, 1.0f);
        return;
    }
	
    #if ENABLE_SHADOW == 1
	if (float(Depth < 0.56) < 0.5) {
		vec3 originalShadow = GetShadow(texture2D(depthtex1, TexCoords).r);
		float shadow_transperency_coef = mix(degree_night_darkness - 0.025f, SHADOW_TRANSPARENCY, state);
		ShadowColor = mix(originalShadow * vec3(shadow_transperency_coef / 0.75), originalShadow, state);
		ShadowColor = mix(ShadowColor, vec3(1), swapDayNight(worldTime));
		vec3 colorRainDayOrNight = mix(vec3(0.2), vec3(1), state);
		ShadowColor = mix(ShadowColor, colorRainDayOrNight, rainStrength);
		
		ShadowColor *= AdjustLightmap(Lightmap.xy).g;
		ShadowColor += shadow_transperency_coef;
	}
	#endif
	
	vec3 Diffuse = Albedo * (LightmapColor + lightBrightnessV * ShadowColor);
	
	/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}
