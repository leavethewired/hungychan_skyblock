#version 120

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

varying vec2 TexCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec2 LightmapCoords;

void main() {
    gl_Position = ftransform();
	TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
	
	vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;
	gl_FogFragCoord = length(pos);
	
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;
}
