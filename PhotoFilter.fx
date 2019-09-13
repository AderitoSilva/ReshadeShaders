/**
 * Photo Filter
 * by ASilva
 *
 * Applies a unique color filter to the input.
 */

uniform float3 FilterColor <
	ui_type = "color";
  ui_label = "Filter Color";
	ui_tooltip = "Color used to filter the input.";
> = float3(1.0, 0.5, 0.25);

uniform float FilterIntensity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
  ui_label = "Filter Intensity";
  ui_tooltip = "Intensity of the color filter.";
> = 0.2;

uniform float TintIntensity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
  ui_label = "Tint Intensity";
  ui_tooltip = "Intensity of the tint. This is a simple multiplicative colorization that is applied in addition to the filter.";
> = 0.0;

#include "ReShade.fxh"

// ---------------------------

float3 ScreenBlend(float3 inputColor, float3 blendColor)
{
	inputColor.r = 1 - (1 - inputColor.r) * (1 - blendColor.r);
	inputColor.g = 1 - (1 - inputColor.g) * (1 - blendColor.g);
	inputColor.b = 1 - (1 - inputColor.b) * (1 - blendColor.b);
	return inputColor;
}


float3 EqualizeLuminance(float3 source, float3 target)
{
    float3 sourceLuminance = dot(source.rgb, float3(0.30, 0.59, 0.11));
   float3 targetLuminance = dot(target.rgb, float3(0.30, 0.59, 0.11));
   float diff = sourceLuminance - targetLuminance;
   
   target.r = 1.0f - (1.0f - target.r) * (1.0f - diff);
   target.g = 1.0f - (1.0f - target.g) * (1.0f - diff);
   target.b = 1.0f - (1.0f - target.b) * (1.0f - diff);
   
   return target;
}


float3 ApplyFilter(float3 inputColor, float3 filter, float amount)
{
	float3 luminance = dot(inputColor.rgb, float3(0.30, 0.59, 0.11));
  
  // Multiply output by filter;
  float3 output = inputColor;
  float diff = inputColor.rgb - filter.rgb;
  output.rgb *= min(filter.rgb + (inputColor.rgb * diff), 1.0f);
	
	// Compensate luminance;
  output = EqualizeLuminance(inputColor, output);
  
  // Blend input with output by the specified amount;
  output.rgb = lerp(inputColor.rgb, output.rgb, amount);
  return output;
}


float3 ApplyTint(float3 inputColor, float3 tintColor, float amount)
{
   float3 luminance = dot(inputColor.rgb, float3(0.30, 0.59, 0.11));
   float3 tintedColor = luminance * tintColor.rgb;
   
   float diff = inputColor.rgb - tintedColor.rgb;
   float3 overlayColor;
   overlayColor.rgb = diff;
   tintedColor = ScreenBlend(tintedColor, overlayColor);
   
   float3 output = inputColor;
   output.rgb = lerp(inputColor.rgb, tintedColor.rgb, amount);
   return output;
}


float3 PhotoFilterPass(float4 vpos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Get current pixel color;
  float3 input = tex2D(ReShade::BackBuffer, uv).rgb;
  float3 output = input;

  // Apply color filter;
  if (FilterIntensity > 0)
  {
  	output = ApplyFilter(input, FilterColor, FilterIntensity);
  }
  
  // Apply tint colorization;
  if (TintIntensity > 0)
  {
  	output = ApplyTint(output, FilterColor, TintIntensity);
  }
  
  // Return output;
  return output;
}


technique PhotoFilter
  < ui_tooltip = "                   .: Photo Filter :.\n\n"
			           "Photo Filter applies a photography color filter with automatic\n"
                 "luminance compensation.\n\n"
                 "It can be used to give the input an aesthetic view that\n"
                 "approximates all colors, so they are less visualy intrusive.\n"
                 "This is similar to the Photo Filter found in Adobe Photoshop.\n\n"
                 "                       by ASilva"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PhotoFilterPass;
	}
}
