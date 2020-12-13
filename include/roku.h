/* Copyright 2020, Trevor Sundberg. See LICENSE.md */
/* All the imports here correspond with functions in `roku.brs` */

#pragma once
#ifndef ROKU_H
#define ROKU_H

void roku_create_surface(int bitsPerPixel, int width, int height);

void roku_set_surface_colors(void* colorTableOffset);

void roku_draw_surface(void* pixelDataOffset);

unsigned int roku_poll_button(void);

enum roku_button {
    ROKU_BACK = 0,
    ROKU_UP = 2,
    ROKU_DOWN = 3,
    ROKU_LEFT = 4,
    ROKU_RIGHT = 5,
    ROKU_OK = 6,
    ROKU_INSTANTREPLAY = 7,
    ROKU_REWIND = 8,
    ROKU_FASTFORWARD = 9,
    ROKU_OPTIONS = 10,
    ROKU_PLAY = 13,
    ROKU_INVALID = 0xFFFFFFFF
};

#endif
