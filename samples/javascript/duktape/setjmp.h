#pragma once
typedef int jmp_buf;

extern int setjmp(jmp_buf env);
extern void longjmp(jmp_buf env, int val);
