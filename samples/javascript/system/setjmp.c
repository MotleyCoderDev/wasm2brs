#include "setjmp.h"
#include <stdio.h>
#include <stdlib.h>
int setjmp(jmp_buf env) {
    return 0;
}
void longjmp(jmp_buf env, int val) {
    fprintf(stderr, "Function 'longjmp' called with value %d and is not yet supported (aborting...)\n", val);
    abort();
}