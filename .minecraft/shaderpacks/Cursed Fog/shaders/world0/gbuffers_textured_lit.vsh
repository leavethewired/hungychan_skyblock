#version 120

out vec2 TexCoords;
out vec4 Color;
out vec2 LightmapCoords;

void main() {
    gl_Position = ftransform();
	TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.xy;
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
	
    Color = gl_Color;
}
