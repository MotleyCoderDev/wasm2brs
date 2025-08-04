/* Copyright 2020, Trevor Sundberg. See LICENSE.md */
/* All the imports here correspond with functions in `roku.brs` */

#pragma once
#ifndef ROKU_H
#define ROKU_H

#define ROKU_BUILTIN(name) __attribute__((__import_name__(#name)))

/*
    This function causes the script to pause for the specified time, without wasting CPU cycles.
    There are 1000 milliseconds in one second.
*/
ROKU_BUILTIN(sleep) void roku_sleep(int milliseconds);

/*
    Create a singleton global surface.
    If bitsPerPixel = 8, then you must call roku_set_surface_colors before roku_draw_surface.
*/
void roku_create_surface(int bitsPerPixel, int width, int height);

/*
    Set the color palette for a created surface. Only valid when bitsPerPixel = 8.
*/
void roku_set_surface_colors(void* colorTable);

/*
    Render the surface to the screen with the given pixel data.
    The pixelData must be of size width * height * (bitsPerPixel / 8).
*/
void roku_draw_surface(void* pixelData);

/*
    Poll to see if any buttons are pressed, released, or held.
    When pressed, the value will match roku_button (e.g. 6 for ROKU_OK).
    When released, the value will be roku_button + 100 (e.g. 106 for ROKU_OK).
    When held / repeated, the value will be roku_button + 1000 (e.g. 1006 for ROKU_OK).
    Returns ROKU_INVALID if there are no button events.
*/
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
