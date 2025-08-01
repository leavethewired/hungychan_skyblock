#version 120

#include "/settings.glsl"

in vec2 TexCoords;
in vec2 LightmapCoords;
in vec4 Color;
in vec3 tangent;
in vec3 viewSpaceGeoNormal;
in vec3 Normal;
uniform int entityId;

uniform sampler2D texture;
uniform sampler2D normals;
uniform vec3 shadowLightPosition;
uniform float rainStrength;

uniform mat4 gbufferModelViewInverse;

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = normalize(cross(tangent,normal));
    return mat3(tangent, bitangent, normal);
}

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

void main(){
    vec4 albedo = texture2D(texture, TexCoords) * Color;
	vec3 shadowLightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
	float diffuseLight = 0.0f;
	state = smoothTransition(worldTime);
	
	vec3 redTone = vec3(1.0, 0.2, 0.2);  // Red-tinted color
	albedo.rgb = mix(albedo.rgb, redTone, 0.25 * state * (1 - rainStrength));  // Adjust the blending factor for intensity
	
	#if PBR == 1
	vec3 viewSpaceInitialTangent = tangent.xyz;
	vec3 viewSpaceTangent = normalize(viewSpaceInitialTangent - dot(viewSpaceInitialTangent, viewSpaceGeoNormal) * viewSpaceGeoNormal);
	
	vec2 normalData = vec2(texture(normals,TexCoords)).xy * 2.0 - 1.0;
	vec3 normalNormalSpace = vec3(normalData.xy,sqrt(1.0 - dot(normalData.xy, normalData.xy)));
	mat3 TBN = tbnNormalTangent(viewSpaceGeoNormal, viewSpaceTangent);
	vec3 normalViewSpace = TBN * normalNormalSpace;
	vec3 normalWorldSpace = mat3(gbufferModelViewInverse) * normalViewSpace;

	diffuseLight = clamp(dot(shadowLightDir, normalWorldSpace), 0.0f, 1.0f);
	#else
	diffuseLight = clamp(dot(shadowLightDir, Normal), 0.0f, 1.0f);
	#endif
	
	if (int(entityId) == 1) {
		diffuseLight = 1;
	}
	
    /* DRAWBUFFERS:02 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(LightmapCoords, diffuseLight, 1.0f);
}
