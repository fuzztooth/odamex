// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// Copyright (C) 2006-2026 by The Odamex Team.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//   ARM NEON optimized rendering routines for Android/ARM devices
//
//-----------------------------------------------------------------------------

#include "odamex.h"

#include "i_sdl.h"
#include "r_intrin.h"

#if defined(__ARM_NEON) || defined(__ARM_NEON__)

#include <assert.h>
#include <arm_neon.h>

#ifdef ANDROID
#include <android/log.h>
#endif

#include "i_system.h"
#include "r_defs.h"
#include "r_draw.h"
#include "r_main.h"
#include "i_video.h"

// Direct rendering (32-bit) functions for ARM NEON optimization:

//
// R_GetBytesUntilAligned
//
static inline uintptr_t R_GetBytesUntilAligned(void* data, uintptr_t alignment)
{
	uintptr_t mask = alignment - 1;
	return (alignment - ((uintptr_t)data & mask)) & mask;
}

//
// R_DrawSpanD_NEON
//
// Optimized floor/ceiling span drawer using ARM NEON intrinsics
//
void R_DrawSpanD_NEON(void)
{
#ifdef RANGECHECK
	if (dspan.x2 < dspan.x1 || dspan.x1 < 0 || dspan.x2 >= viewwidth ||
		dspan.y >= viewheight || dspan.y < 0)
	{
		PrintFmt(PRINT_HIGH, "R_DrawLevelSpan: {} to {} at {}", dspan.x1, dspan.x2, dspan.y);
		return;
	}
#endif

	const int width = dspan.x2 - dspan.x1 + 1;

	// TODO: store flats in column-major format and swap u and v
	dsfixed_t ufrac = dspan.yfrac;
	dsfixed_t vfrac = dspan.xfrac;
	dsfixed_t ustep = dspan.ystep;
	dsfixed_t vstep = dspan.xstep;

	const byte* source = dspan.source;
	argb_t* dest = (argb_t*)dspan.destination + dspan.y * dspan.pitch_in_pixels + dspan.x1;

	shaderef_t colormap = dspan.colormap;

	const int texture_width_bits = 6, texture_height_bits = 6;

	const unsigned int umask = ((1 << texture_width_bits) - 1) << texture_height_bits;
	const unsigned int vmask = (1 << texture_height_bits) - 1;
	const int ushift = FRACBITS - texture_height_bits + 10;
	const int vshift = FRACBITS + 10;

	int align = R_GetBytesUntilAligned(dest, 16) / sizeof(argb_t);
	if (align > width)
		align = width;

	int batches = (width - align) / 4;
	int remainder = (width - align) & 3;

	// Blit until we align ourselves with a 16-byte offset for NEON:
	while (align--)
	{
		unsigned int u = (ufrac >> ushift) & umask;
		unsigned int v = (vfrac >> vshift) & vmask;
		*dest++ = colormap.shade(source[u | v]);
		ufrac += ustep;
		vfrac += vstep;
	}

	// Main NEON loop - process 4 pixels at once
	if (batches > 0)
	{
		// Setup NEON constants
		int32x4_t ustep_vec = vdupq_n_s32((int32_t)(ustep * 4));
		int32x4_t vstep_vec = vdupq_n_s32((int32_t)(vstep * 4));
		
		// Create vectors for u and v increments
		int32_t u_offsets[4] = {0, (int32_t)ustep, (int32_t)(ustep * 2), (int32_t)(ustep * 3)};
		int32_t v_offsets[4] = {0, (int32_t)vstep, (int32_t)(vstep * 2), (int32_t)(vstep * 3)};
		
		int32x4_t u_offset_vec = vld1q_s32(u_offsets);
		int32x4_t v_offset_vec = vld1q_s32(v_offsets);
		
		int32x4_t ufrac_vec = vaddq_s32(vdupq_n_s32((int32_t)ufrac), u_offset_vec);
		int32x4_t vfrac_vec = vaddq_s32(vdupq_n_s32((int32_t)vfrac), v_offset_vec);
		
		// Get shademap pointer for direct ARGB lookup
		const argb_t* shademap_data = colormap.m_shademap;

		while (batches--)
		{
			// Calculate texture coordinates for 4 pixels
			uint32_t u0 = (vgetq_lane_s32(ufrac_vec, 0) >> ushift) & umask;
			uint32_t v0 = (vgetq_lane_s32(vfrac_vec, 0) >> vshift) & vmask;
			uint32_t u1 = (vgetq_lane_s32(ufrac_vec, 1) >> ushift) & umask;
			uint32_t v1 = (vgetq_lane_s32(vfrac_vec, 1) >> vshift) & vmask;
			uint32_t u2 = (vgetq_lane_s32(ufrac_vec, 2) >> ushift) & umask;
			uint32_t v2 = (vgetq_lane_s32(vfrac_vec, 2) >> vshift) & vmask;
			uint32_t u3 = (vgetq_lane_s32(ufrac_vec, 3) >> ushift) & umask;
			uint32_t v3 = (vgetq_lane_s32(vfrac_vec, 3) >> vshift) & vmask;

			// Fetch palette indices
			byte p0 = source[u0 | v0];
			byte p1 = source[u1 | v1];
			byte p2 = source[u2 | v2];
			byte p3 = source[u3 | v3];

			// Load 4 ARGB pixels from shademap using palette indices
			uint32_t colors[4];
			colors[0] = shademap_data[p0];
			colors[1] = shademap_data[p1];
			colors[2] = shademap_data[p2];
			colors[3] = shademap_data[p3];
			
			// Store 4 pixels at once
			uint32x4_t pixel_vec = vld1q_u32(colors);
			vst1q_u32((uint32_t*)dest, pixel_vec);

			dest += 4;
			
			// Increment texture coordinates
			ufrac_vec = vaddq_s32(ufrac_vec, ustep_vec);
			vfrac_vec = vaddq_s32(vfrac_vec, vstep_vec);
		}

		ufrac = vgetq_lane_s32(ufrac_vec, 0);
		vfrac = vgetq_lane_s32(vfrac_vec, 0);
	}

	// Handle remaining pixels
	while (remainder--)
	{
		unsigned int u = (ufrac >> ushift) & umask;
		unsigned int v = (vfrac >> vshift) & vmask;
		*dest++ = colormap.shade(source[u | v]);
		ufrac += ustep;
		vfrac += vstep;
	}
}

//
// R_DrawSlopeSpanD_NEON
//
// For now, use the C version - slope spans are more complex
//
void R_DrawSlopeSpanD_NEON(void)
{
	R_DrawSlopeSpanD_c();
}

//
// r_dimpatchD_NEON
//
// Optimized dim patch using NEON
//
void r_dimpatchD_NEON(IWindowSurface* surface, argb_t color, int alpha, int x1, int y1, int w, int h)
{
#ifdef ANDROID
	static bool logged = false;
	if (!logged) {
		__android_log_print(ANDROID_LOG_INFO, "Odamex", "r_dimpatchD_NEON called! color=0x%08x alpha=%d", color, alpha);
		logged = true;
	}
#endif

	int surface_width = surface->getWidth();
	int surface_height = surface->getHeight();
	int surface_pitch_pixels = surface->getPitchInPixels();

	int x2 = x1 + w, y2 = y1 + h;

	if (x1 < 0)
		x1 = 0;
	if (x1 > surface_width)
		return;
	if (y1 < 0)
		y1 = 0;
	if (y1 > surface_height)
		return;

	if (x2 < 0)
		return;
	if (x2 > surface_width)
		x2 = surface_width;
	if (y2 < 0)
		return;
	if (y2 > surface_height)
		y2 = surface_height;

	if (x2 <= x1 || y2 <= y1)
		return;

	w = x2 - x1;
	h = y2 - y1;

	argb_t* dest = (argb_t*)surface->getBuffer() + y1 * surface_pitch_pixels + x1;

	int invAlpha = 256 - alpha;

	// Extract source color components (format: R=24, G=16, B=8, X=0)
	uint16_t sr = (color >> 24) & 0xFF;
	uint16_t sg = (color >> 16) & 0xFF;
	uint16_t sb = (color >> 8) & 0xFF;
	
	// Create NEON vectors for source color and alpha values
	uint16x8_t sr_vec = vdupq_n_u16(sr);
	uint16x8_t sg_vec = vdupq_n_u16(sg);
	uint16x8_t sb_vec = vdupq_n_u16(sb);
	uint16x8_t alpha_vec = vdupq_n_u16(alpha);
	uint16x8_t inv_alpha_vec = vdupq_n_u16(invAlpha);

	for (int y = 0; y < h; y++)
	{
		argb_t* line = dest;
		int count = w;

		// Process 4 pixels at a time with NEON
		while (count >= 4)
		{
			// Load 4 destination pixels
			uint32x4_t dest_pixels = vld1q_u32((uint32_t*)line);
			
			// Extract R, G, B channels from 4 pixels
			// Shift right and mask to get each channel
			uint16x4_t dr_low = vmovn_u32(vshrq_n_u32(dest_pixels, 24));  // R channel
			uint16x4_t dg_low = vmovn_u32(vshrq_n_u32(vandq_u32(dest_pixels, vdupq_n_u32(0x00FF0000)), 16)); // G channel
			uint16x4_t db_low = vmovn_u32(vshrq_n_u32(vandq_u32(dest_pixels, vdupq_n_u32(0x0000FF00)), 8));  // B channel
			uint32x4_t da_masked = vandq_u32(dest_pixels, vdupq_n_u32(0x000000FF));  // Preserve low byte
			
			// Expand to 16-bit for multiplication
			uint16x8_t dr = vcombine_u16(dr_low, vdup_n_u16(0));
			uint16x8_t dg = vcombine_u16(dg_low, vdup_n_u16(0));
			uint16x8_t db = vcombine_u16(db_low, vdup_n_u16(0));
			
			// Alpha blend: result = (src * alpha + dest * invAlpha) >> 8
			uint16x8_t r_blend = vshrq_n_u16(vaddq_u16(vmulq_u16(sr_vec, alpha_vec), vmulq_u16(dr, inv_alpha_vec)), 8);
			uint16x8_t g_blend = vshrq_n_u16(vaddq_u16(vmulq_u16(sg_vec, alpha_vec), vmulq_u16(dg, inv_alpha_vec)), 8);
			uint16x8_t b_blend = vshrq_n_u16(vaddq_u16(vmulq_u16(sb_vec, alpha_vec), vmulq_u16(db, inv_alpha_vec)), 8);
			
			// Pack back into 32-bit pixels (R=24, G=16, B=8, X=0)
			uint32x4_t r_shifted = vshlq_n_u32(vmovl_u16(vget_low_u16(r_blend)), 24);
			uint32x4_t g_shifted = vshlq_n_u32(vmovl_u16(vget_low_u16(g_blend)), 16);
			uint32x4_t b_shifted = vshlq_n_u32(vmovl_u16(vget_low_u16(b_blend)), 8);
			
			uint32x4_t result = vorrq_u32(vorrq_u32(r_shifted, g_shifted), vorrq_u32(b_shifted, da_masked));
			
			// Store 4 blended pixels
			vst1q_u32((uint32_t*)line, result);
			
			line += 4;
			count -= 4;
		}

		// Handle remaining pixels
		while (count--)
		{
			argb_t d = *line;
			// Framebuffer is in texture format: R=24, G=16, B=8, X=0
			int dr = (d >> 24) & 0xFF;
			int dg = (d >> 16) & 0xFF;
			int db = (d >> 8) & 0xFF;

			// Input color (argb_t) uses same format: R=24, G=16, B=8
			int sr = (color >> 24) & 0xFF;
			int sg = (color >> 16) & 0xFF;
			int sb = (color >> 8) & 0xFF;

			dr = (sr * alpha + dr * invAlpha) >> 8;
			dg = (sg * alpha + dg * invAlpha) >> 8;
			db = (sb * alpha + db * invAlpha) >> 8;

			// Write back in same format: R=24, G=16, B=8
			*line++ = (dr << 24) | (dg << 16) | (db << 8) | (d & 0xFF);
		}

		dest += surface_pitch_pixels;
	}
}

#endif // __ARM_NEON
