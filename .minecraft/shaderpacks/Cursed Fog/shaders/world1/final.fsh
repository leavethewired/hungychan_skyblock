#version 130

// Shader by LoLip_p

#include "/settings.glsl"

uniform sampler2D colortex4;
uniform float frameTimeCounter;

uniform float viewWidth;
uniform float viewHeight;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

varying vec4 color;
varying vec2 TexCoords;

float ab = CHROMATIC_ABERRATION;
float stripeWidth = BLACK_STRIPES_WIDTH;
float stripeEdgeSoftness = BLACK_STRIPES_SOFT;
float grainStrenght = GRAIN_STRENGTH;
float diractionStrenght = DIRECTION_STRENGTH;

// Function to convert black to dark purple
vec3 blackToDarkPurple(vec3 color)
{
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722)); // Calculate brightness using luminance formula
    vec3 darkPurple = vec3(0.02, 0.00, 0.04); // Define dark purple color

    // If the brightness is very low (close to black), blend it towards dark purple
    return mix(darkPurple, color, smoothstep(0.0, 0.05, brightness));
}

// ACES Tone Mapping Function
vec3 toneMappingACES(const vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 rgb2yuv(vec3 rgb)
{
    float y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    return vec3(y, 0.493 * (rgb.b - y), 0.877 * (rgb.r - y));
}

vec3 yuv2rgb(vec3 yuv)
{
    float y = yuv.x;
    float u = yuv.y;
    float v = yuv.z;
    
    return vec3
    (
        y + 1.0 / 0.877 * v,
        y - 0.39393 * u - 0.58081 * v,
        y + 1.0 / 0.493 * u
    );
}

float RandomValue(inout uint state)
{
    state = state * 747796405u + 2891336453u;
    uint result = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    result = (result >> 22u) ^ result;
    state *= result;
    return float(result) / 4294967295.0;
}

float RandomValueNormalDistribution(inout uint n)
{
    float theta = 2.0 * 3.14 * RandomValue(n);
    float rho = sqrt(-2.0 * log(RandomValue(n)));
    n += uint(rho * cos(theta));
    return rho * cos(theta);
}

vec3 RandomDirection(inout uint n)
{
    float x = RandomValueNormalDistribution(n);
    float y = RandomValueNormalDistribution(n);
    float z = RandomValueNormalDistribution(n);
    return normalize(vec3(x, y, z));
}

// Function to simulate CRT scan lines and pixel grid effect
vec3 applyCRT(vec2 uv)
{
    // Fisheye effect
    vec2 centeredCoord = (uv - 0.5) * 0.925 + 0.5;
    float distanceF = length(centeredCoord - 0.5);

	#if INTERLACED_SCAN == 1
    float interlaceOffset = fract(uv.y * (viewHeight / 10.0)) > 0.5 ? 1.0 : 0.0;
    interlaceOffset *= (2.0 / viewWidth);
    interlaceOffset *= length(cameraPosition - previousCameraPosition) * 5;
    uv.x += interlaceOffset;
    uv.x += interlaceOffset;
	#endif

    // Sample the color again with downsampled coordinates
    vec3 downsampledColor;

    // Chromatic aberration
    vec2 redUV = uv + vec2(ab, ab) * distanceF;
    vec2 blueUV = uv + vec2(-ab, -ab) * distanceF;
    downsampledColor.r = texture2D(colortex4, redUV).r;
	downsampledColor.g = texture2D(colortex4, uv).g;
    downsampledColor.b = texture2D(colortex4, blueUV).b;
	
    // Convert black (low brightness) colors to dark purple
    downsampledColor = blackToDarkPurple(downsampledColor);

	#if R_DIRECTION == 1
	ivec2 pixels = ivec2(viewWidth, viewHeight);
    ivec2 pixelCoordC = ivec2(uv * vec2(pixels));
    pixelCoordC = ivec2(floor(vec2(pixelCoordC) / 4.0) * 4.0);
    uint pixelIndex = uint(pixelCoordC.y * pixels.x + pixelCoordC.x);
    uint rnd = pixelIndex + uint(fract(frameTimeCounter) * viewHeight * viewHeight);
	
	downsampledColor.rgb = rgb2yuv(downsampledColor.rgb);
    downsampledColor.yz += RandomDirection(rnd).xy * diractionStrenght;
	downsampledColor.rgb = yuv2rgb(downsampledColor.rgb);
	#endif

	#if BLACK_STRIPES == 1
	float leftStripe = smoothstep(stripeWidth, stripeWidth - stripeEdgeSoftness, uv.x);
    float rightStripe = smoothstep(1.0 - stripeWidth, 1.0 - (stripeWidth - stripeEdgeSoftness), uv.x);
    float stripeEffect = max(leftStripe, rightStripe);
    downsampledColor = mix(downsampledColor, vec3(0.05), stripeEffect);
	#endif
	
	#if CRT_MASK == 1
    float dotMask = sin(3.14 * uv.x * 800.0 * viewWidth) * sin(3.14 * uv.y * 800.0 * viewHeight);
    downsampledColor *= mix(0.85, 1.0, dotMask);
	
	// Slight vignette effect
    float vignette = 1.0 - dot(uv - 0.5, uv - 0.5) * 0.5;
	downsampledColor *= vignette;
	#endif

    #if GRAIN == 1
    float noise = (fract(sin(dot(uv, vec2(12.9898, 78.233 * frameTimeCounter))) * 43758.5453) - 0.5) * grainStrenght;
    downsampledColor.rgb += vec3(noise);
	#endif

    return downsampledColor;
}

void main()
{
    // Get the UV coordinates
    vec2 uv = TexCoords;

    // Apply CRT effect
    vec3 crtColor = applyCRT(uv);
	
    vec3 tonedColor = toneMappingACES(crtColor);

    // Apply saturation, brightness, and contrast
    float average = (tonedColor.r + tonedColor.g + tonedColor.b) / 3.0;
    tonedColor.rgb = mix(vec3(average), tonedColor.rgb, SATURATION);
	tonedColor.rgb += BRIGHTNESS;
    tonedColor.rgb = ((tonedColor.rgb - 0.5) * CONTRAST) + 0.5;

    // Output the final color
    gl_FragData[0] = vec4(tonedColor, color.a);
}
