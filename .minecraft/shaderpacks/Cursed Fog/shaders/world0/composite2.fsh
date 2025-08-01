#version 120

#include "/settings.glsl"

in vec2 TexCoords;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

#if SSR == 1
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

float cdist(vec2 coord) {
	return clamp(1.0 - max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0, 0.0, 1.0);
}

vec3 screenSpace(vec2 coord, float depth){
	vec4 pos = gbufferProjectionInverse * (vec4(coord, depth, 1.0) * 2.0 - 1.0);
	return pos.xyz/pos.w;
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 raytrace(vec4 color, vec3 normal) {
	vec3 fragpos0 = screenSpace(TexCoords.xy, texture2D(depthtex0, TexCoords.xy).x);
	vec3 rvector = reflect(fragpos0.xyz, normal.xyz);
	rvector = normalize(rvector);
	
	vec3 start = fragpos0 + rvector;
	vec3 tvector = rvector;
    int sr = 0;
	const int maxf = 3;
	const float ref = 0.2;
	const int rsteps = 15;
	const float inc = 2.2;
    for(int i=0;i<rsteps;i++) {
        vec3 pos = nvec3(gbufferProjection * vec4(start, 1.0)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 fragpos1 = screenSpace(pos.xy, texture2D(depthtex1, pos.st).x);
        float err = distance(start, fragpos1);
		if(err < pow(length(rvector),1.35)) {
                sr++;
                if(sr >= maxf) {
                    color = texture2D(colortex0, pos.st);
					color.a = cdist(pos.st);
					break;
                }
				tvector -= rvector;
                rvector *= ref;
		}
        rvector *= inc;
        tvector += rvector;
		start = fragpos0 + tvector;
	}
    return color;
}
#endif

void main() {
	vec3 color = texture2D(colortex0, TexCoords).rgb;
	
	#if SSR == 1
	if(isEyeInWater != 1) {
		vec2 normal = texture2D(colortex3, TexCoords).xy;
		vec3 newnormal = decode(normal.xy);
	
		vec4 relfcolor = vec4(color, 1.0f);
		vec4 reflection = raytrace(relfcolor, newnormal.xyz);	
	
		vec3 normfrag1 = normalize(screenSpace(TexCoords, texture2D(depthtex1, TexCoords).x));

		vec3 rVector = reflect(normfrag1, normalize(newnormal.xyz));
		vec3 hV= normalize(rVector - normfrag1);

		float normalDotEye = dot(hV, normfrag1);
		float F0 = 0.09;
		float fresnel = pow(clamp(1.0 + normalDotEye, 0.0, 1.0), 4.0);
		fresnel = fresnel + F0 * (1.0 - fresnel);
	
		reflection.rgb = mix(relfcolor.rgb, reflection.rgb, reflection.a);
		color.rgb = mix(color.rgb, reflection.rgb, fresnel*1.25);
	}
	#endif
	
	/*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color, 1.0f);
}
