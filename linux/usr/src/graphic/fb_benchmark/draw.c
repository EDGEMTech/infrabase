/*******************************************************************
 *
 * draw.c - Draws a solid color background, on each call the color
 * is decremented or incremented
 *
 * Copyright (c) 2025 EDGEMTech Ltd.
 *
 * Author: EDGEMTech Ltd, Erik Tagirov (erik.tagirov@edgemtech.ch)
 *
 ******************************************************************/
#include "drm-common.h"
#include <gbm.h>
#include <string.h>


/**
 * @param struct drm_fb the framebuffer on wich to draw
 * @note this function replaced the cube that was drawn with OpenGL.
 */
void draw_solid_color(struct drm_fb *fb)
{
	uint32_t size;
	uint32_t *data = (uint32_t *)fb->buf;
	uint32_t width = fb->width;
	uint32_t height = fb->height;
	static uint8_t color = 0;
	static bool decrease = false;
	uint32_t stride = fb->stride;

	size = height * stride;
	memset(data, color, size);

	if (decrease == true) {
		color--;
	} else {
		color++;
	}

	if (color == 0xFF) {
		decrease = true;
	} else if (color == 0x0) {
		decrease = false;
	}
}

