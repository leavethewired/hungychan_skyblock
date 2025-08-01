/* 
BSL Shaders v10 Series by Capt Tatsu 
https://capttatsu.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec, eastVec;

varying vec4 color;

//Uniforms//
uniform int bedrockLevel;
uniform int frameCounter;
uniform int isEyeInWater;
uniform int moonPhase;
uniform int worldTime;

uniform float blindFactor, darknessFactor, nightVision;
uniform float cloudHeight;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform vec3 relativeEyePosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform sampler2D noisetex;

#if DYNAMIC_HANDLIGHT > 0
uniform int heldBlockLightValue, heldBlockLightValue2;
#endif

#if defined MULTICOLORED_BLOCKLIGHT || defined MCBL_SS
uniform int heldItemId, heldItemId2;
#endif

#ifdef MULTICOLORED_BLOCKLIGHT
uniform sampler3D lighttex0;
uniform sampler3D lighttex1;
#endif

#ifdef MCBL_SS
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 previousCameraPosition;

uniform sampler2D colortex9;
#endif

#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
uniform float dhFarPlane;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec, upVec) * 10.0 + 0.5, 0.0, 1.0);
float moonVisibility = clamp(dot(-sunVec, upVec) * 10.0 + 0.5, 0.0, 1.0);

#ifdef WORLD_TIME_ANIMATION
float time = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float time = frameTimeCounter * ANIMATION_SPEED;
#endif

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/lightSkyColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/atmospherics/weatherDensity.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/lighting/dynamicHandlight.glsl"
#include "/lib/lighting/forwardLighting.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef MULTICOLORED_BLOCKLIGHT
#include "/lib/util/voxelMapHelper.glsl"
#endif

#if defined MULTICOLORED_BLOCKLIGHT || defined MCBL_SS
#include "/lib/lighting/coloredBlocklight.glsl"
#endif

//Program//
void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;

	if (albedo.a > 0.001) {
		vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#if defined TAA
		vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
		#else
		vec3 viewPos = ToNDC(screenPos);
		#endif
		vec3 worldPos = ToWorld(viewPos);
		
		#if DYNAMIC_HANDLIGHT == 2
		lightmap = ApplyDynamicHandlight(lightmap, worldPos);
		#endif

		#ifdef TOON_LIGHTMAP
		lightmap = floor(lightmap * 14.999 * (0.75 + 0.25 * color.a)) / 14.0;
		lightmap = clamp(lightmap, vec2(0.0), vec2(1.0));
		#endif

    	albedo.rgb = pow(albedo.rgb, vec3(2.2));

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.35);
		#endif

		float NoL = 1.0;
		//NoL = clamp(dot(normal, lightVec) * 1.01 - 0.01, 0.0, 1.0);

		float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
		float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);
		float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
			  vanillaDiffuse*= vanillaDiffuse;


		#if defined MULTICOLORED_BLOCKLIGHT || defined MCBL_SS
		blocklightCol = ApplyMultiColoredBlocklight(blocklightCol, screenPos, worldPos, normal);
		#endif
		
		vec3 shadow = vec3(0.0);
		GetLighting(albedo.rgb, shadow, viewPos, worldPos, normal, lightmap, 1.0, NoL, 
					1.0, 1.0, 0.0, 0.0, 0.0);

		#if defined FOG && MC_VERSION >= 11500
		Fog(albedo.rgb, viewPos);
		#endif

		#if ALPHA_BLEND == 0
		albedo.rgb = sqrt(max(albedo.rgb, vec3(0.0)));
		#endif
	}
	
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;

	#ifdef MCBL_SS
		/* DRAWBUFFERS:08 */
		gl_FragData[1] = vec4(0.0,0.0,0.0,1.0);

		#ifdef ADVANCED_MATERIALS
		/* DRAWBUFFERS:08367 */
		gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
		gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
		gl_FragData[4] = vec4(0.0, 0.0, 0.0, 1.0);
		#endif
	#else
		#ifdef ADVANCED_MATERIALS
		/* DRAWBUFFERS:0367 */
		gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
		gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
		gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
		#endif
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec, eastVec;

varying vec4 color;

//Uniforms//
uniform int worldTime;

uniform float frameTimeCounter;
uniform float timeAngle;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

#ifdef TAA
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float time = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float time = frameTimeCounter * ANIMATION_SPEED;
#endif

//Includes//
#ifdef TAA
#include "/lib/util/jitter.glsl"
#endif

#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	normal = normalize(gl_NormalMatrix * gl_Normal);
    
	color = gl_Color;

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);

    #ifdef WORLD_CURVATURE
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	position.y -= WorldCurvature(position.xz);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
	gl_Position = ftransform();
    #endif
	
	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif