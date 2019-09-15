/*
 * Photo Filter
 * by Aderito Silva
 *
 * Applies photographic color filtering to the input.
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
  ui_tooltip = "Intensity of the filter.";
> = 0.2;

uniform float TintIntensity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
  ui_label = "Tint Intensity";
  ui_tooltip = "Intensity of the tint.\n\n"
               "This is a simple multiplicative colorization that is applied\n"
               "to the output in addition to the filter. Unlike the filter,\n"
               "tint with full intensity (1.0) will give you a monochrome output.";
> = 0.0;

#include "ReShade.fxh"


// ================================


// Gets the luminance of the specified color.
float GetLuminance(float3 color)
{
  return dot(color.rgb, float3(0.30f, 0.59f, 0.11f));
}


// Blends the specified blend color over the specified 
// base color.
float3 ScreenBlend(float3 baseColor, float3 blendColor)
{
   return float3
   (
     1f - (1f - baseColor.r) * (1f - blendColor.r),
     1f - (1f - baseColor.g) * (1f - blendColor.g),
     1f - (1f - baseColor.b) * (1f - blendColor.b)
   );
}


// Gives the specified target color the same luminance of the 
// specified source color.
float3 EqualizeLuminance(float3 sourceColor, float3 targetColor)
{
  // Blend the luminance difference of both colors with the target color.
  return ScreenBlend(targetColor, GetLuminance(sourceColor) - GetLuminance(targetColor));
}


// Gets the color that results from applying the specified filter color 
// to the specified original color with the specified opacity.
float3 ApplyFilter(float3 originalColor, float3 filterColor, float opacity)
{
  // Calculate the filtered color.
  float3 diff = originalColor - filterColor;  // Difference between both colors.
  float3 filteredColor = originalColor * min(filterColor + originalColor * diff, 1f);

	// Preserve original color luminance.
  filteredColor = EqualizeLuminance(originalColor, filteredColor);
  
  // Return the filtered color over the original color with the specified opacity.
  return lerp(originalColor, filteredColor, opacity);
}


// Gets the color that results from applying the specified tint color 
// to the specified original color with the specified opacity.
float3 ApplyTint(float3 originalColor, float3 tintColor, float opacity)
{
  // Calculate the tinted color. This is a simple multiplication blend.
  float3 tintedColor = originalColor * tintColor;

  // Preserve original color luminance.
  tintedColor = EqualizeLuminance(originalColor, tintedColor);
  
  // Return the tinted color over the original color with the specified opacity.
  return lerp(originalColor, tintedColor, opacity);
}


float3 PhotoFilterPass(float4 vpos : SV_Position, float2 textCoord : TexCoord) : SV_Target
{
	// Get current pixel color.
  float3 input = tex2D(ReShade::BackBuffer, textCoord).rgb;
  float3 output = input;

  // Apply color filter.
  if (FilterIntensity > 0.0)
  {
  	output = ApplyFilter(input, FilterColor, FilterIntensity);
  }
  
  // Apply tint colorization.
  if (TintIntensity > 0.0)
  {
  	output = ApplyTint(output, FilterColor, TintIntensity);
  }
  
  // Return output.
  return output;
}


// ===================================


technique PhotoFilter
  < ui_tooltip = "Photo Filter :.\n\n"
			           "Photo Filter applies photographic color filtering to an output,\n"
                 "while preserving the original color luminance.\n\n"
                 "It can be used to give the input an aesthetic view that\n"
                 "reduces hue variance, so colors are less visualy intrusive.\n"
                 "This is similar to the Photo Filter found in Adobe Photoshop,\n"
                 "although not exactly identical.\n\n"
                 "by Aderito Silva"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PhotoFilterPass;
	}
}
