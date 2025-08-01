#version 130

#include "/settings.glsl"

uniform sampler2D colortex4;
uniform float viewWidth, viewHeight;

in vec2 TexCoords;

const lowp float edgeThresholdMin = 0.03125;
const lowp float edgeThresholdMax = 0.125;
const lowp float subpixelQuality = 0.75;
const int iterations = 12;
const lowp float quality[12] = float[12] (1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0);

float GetLuminance(vec3 color)
{
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void FXAA311(inout vec3 color)
{
    lowp vec2 view = 1.0 / vec2(viewWidth, viewHeight);
	
    lowp float lumaCenter = GetLuminance(color);
	ivec2 texelCoord = ivec2(gl_FragCoord.xy);

    lowp float lumaDown  = GetLuminance(texelFetch(colortex4, texelCoord + ivec2( 0, -1), 0).rgb);
    lowp float lumaUp    = GetLuminance(texelFetch(colortex4, texelCoord + ivec2( 0,  1), 0).rgb);
    lowp float lumaLeft  = GetLuminance(texelFetch(colortex4, texelCoord + ivec2(-1,  0), 0).rgb);
    lowp float lumaRight = GetLuminance(texelFetch(colortex4, texelCoord + ivec2( 1,  0), 0).rgb);

    lowp float lumaMin = min(lumaCenter, min(min(lumaDown, lumaUp), min(lumaLeft, lumaRight)));
    lowp float lumaMax = max(lumaCenter, max(max(lumaDown, lumaUp), max(lumaLeft, lumaRight)));
    lowp float lumaRange = lumaMax - lumaMin;

    if (lumaRange > max(edgeThresholdMin, lumaMax * edgeThresholdMax))
	{
        float lumaDownLeft  = GetLuminance(texelFetch(colortex4, texelCoord + ivec2(-1, -1), 0).rgb);
        float lumaUpRight   = GetLuminance(texelFetch(colortex4, texelCoord + ivec2( 1,  1), 0).rgb);
        float lumaUpLeft    = GetLuminance(texelFetch(colortex4, texelCoord + ivec2(-1,  1), 0).rgb);
        float lumaDownRight = GetLuminance(texelFetch(colortex4, texelCoord + ivec2( 1, -1), 0).rgb);

        float lumaDownUp    = lumaDown + lumaUp;
        float lumaLeftRight = lumaLeft + lumaRight;

        float lumaLeftCorners  = lumaDownLeft  + lumaUpLeft;
        float lumaDownCorners  = lumaDownLeft  + lumaDownRight;
        float lumaRightCorners = lumaDownRight + lumaUpRight;
        float lumaUpCorners    = lumaUpRight   + lumaUpLeft;

        float edgeHorizontal = abs(-2.0 * lumaLeft   + lumaLeftCorners ) +
                               abs(-2.0 * lumaCenter + lumaDownUp      ) * 2.0 +
                               abs(-2.0 * lumaRight  + lumaRightCorners);
        float edgeVertical   = abs(-2.0 * lumaUp     + lumaUpCorners   ) +
                               abs(-2.0 * lumaCenter + lumaLeftRight   ) * 2.0 +
                               abs(-2.0 * lumaDown   + lumaDownCorners );

        bool isHorizontal = (edgeHorizontal >= edgeVertical);

        float luma1 = isHorizontal ? lumaDown : lumaLeft;
        float luma2 = isHorizontal ? lumaUp : lumaRight;
        float gradient1 = luma1 - lumaCenter;
        float gradient2 = luma2 - lumaCenter;

        bool is1Steepest = abs(gradient1) >= abs(gradient2);
        float gradientScaled = 0.25 * max(abs(gradient1), abs(gradient2));

        float stepLength = isHorizontal ? view.y : view.x;

        float lumaLocalAverage = 0.0;

        if (is1Steepest)
		{
            stepLength = - stepLength;
            lumaLocalAverage = 0.5 * (luma1 + lumaCenter);
        }
		else
		{
            lumaLocalAverage = 0.5 * (luma2 + lumaCenter);
        }

        vec2 currentUv = TexCoords;
        if (isHorizontal)
		{
            currentUv.y += stepLength * 0.5;
        }
		else
		{
            currentUv.x += stepLength * 0.5;
        }

        vec2 offset = isHorizontal ? vec2(view.x, 0.0) : vec2(0.0, view.y);

        vec2 uv1 = currentUv - offset;
        vec2 uv2 = currentUv + offset;

        float lumaEnd1 = GetLuminance(texture2D(colortex4, uv1).rgb);
        float lumaEnd2 = GetLuminance(texture2D(colortex4, uv2).rgb);
			
        lumaEnd1 -= lumaLocalAverage;
        lumaEnd2 -= lumaLocalAverage;

        bool reached1 = abs(lumaEnd1) >= gradientScaled;
        bool reached2 = abs(lumaEnd2) >= gradientScaled;
        bool reachedBoth = reached1 && reached2;

        if (!reached1)
		{
            uv1 -= offset;
        }
        if (!reached2)
		{
            uv2 += offset;
        }

        if (!reachedBoth)
		{
            for (int i = 2; i < iterations; i++)
			{
                if (!reached1)
				{
                    lumaEnd1 = GetLuminance(texture2D(colortex4, uv1).rgb);
                    lumaEnd1 = lumaEnd1 - lumaLocalAverage;
                }
                if (!reached2)
				{
				    lumaEnd2 = GetLuminance(texture2D(colortex4, uv2).rgb);
                    lumaEnd2 = lumaEnd2 - lumaLocalAverage;
                }

                reached1 = abs(lumaEnd1) >= gradientScaled;
                reached2 = abs(lumaEnd2) >= gradientScaled;
                reachedBoth = reached1 && reached2;

                if (!reached1)
				{
                    uv1 -= offset * quality[i];
                }
                if (!reached2)
				{
                    uv2 += offset * quality[i];
                }

                if (reachedBoth) break;
            }
        }

        float distance1 = isHorizontal ? (TexCoords.x - uv1.x) : (TexCoords.y - uv1.y);
        float distance2 = isHorizontal ? (uv2.x - TexCoords.x) : (uv2.y - TexCoords.y);

        bool isDirection1 = distance1 < distance2;
        float distanceFinal = min(distance1, distance2);

        float edgeThickness = (distance1 + distance2);

        float pixelOffset = - distanceFinal / edgeThickness + 0.5;

        bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;

        bool correctVariation = ((isDirection1 ? lumaEnd1 : lumaEnd2) < 0.0) != isLumaCenterSmaller;

        float finalOffset = correctVariation ? pixelOffset : 0.0;

        float lumaAverage = (1.0 / 12.0) * (2.0 * (lumaDownUp + lumaLeftRight) + lumaLeftCorners + lumaRightCorners);
        float subPixelOffset1 = clamp(abs(lumaAverage - lumaCenter) / lumaRange, 0.0, 1.0);
        float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
        float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * subpixelQuality;

        finalOffset = max(finalOffset, subPixelOffsetFinal);

        // Compute the final UV coordinates.
		vec2 finalUv = TexCoords;
        if (isHorizontal) {
            finalUv.y += finalOffset * stepLength;
        } else {
            finalUv.x += finalOffset * stepLength;
        }

        color = texture2D(colortex4, finalUv).rgb;
    }
}

void main() {
    lowp vec3 color = texture2D(colortex4, TexCoords).rgb;
	
	#if ANTI_ALIASING == 1
	FXAA311(color);
    #endif
	
    /* DRAWBUFFERS:4 */
    gl_FragData[0] = vec4(color, 1.0f);
}
