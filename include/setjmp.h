/* Copyright 2020, Trevor Sundberg. See LICENSE.md */
#pragma once
#ifndef SETJMP_H

#include <stdio.h>
#include <stdlib.h>

typedef int jmp_buf;

static int setjmp(jmp_buf env) {
    return 0;
}

static void longjmp(jmp_buf env, int val) {
    fprintf(stderr, "Function 'longjmp' called with value %d and is not yet supported (aborting...)\n", val);
    abort();
}

#endif
