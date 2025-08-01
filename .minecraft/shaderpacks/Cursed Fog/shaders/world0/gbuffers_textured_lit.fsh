#version 120

in vec2 TexCoords;
in vec4 Color;
in vec2 LightmapCoords;

uniform sampler2D texture;
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
    vec4 albedo = texture2D(texture, TexCoords);
	albedo.rgb *= Color.rgb;
	
	state = smoothTransition(worldTime);
	
	albedo.rgb *= mix(vec3(1), vec3(1.0, 0.7, 0.7), state);
	
    /* DRAWBUFFERS:02 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(LightmapCoords, 1.0f, 1.0f);
}
