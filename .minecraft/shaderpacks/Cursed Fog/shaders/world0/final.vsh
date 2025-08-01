#version 120

// Shader by LoLip_p

varying vec2 TexCoords;

void main() {
    gl_Position = ftransform();
	TexCoords = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
