cmake_minimum_required(VERSION 3.13.4)
project(javascript)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fwhole-program")

add_executable(javascript main.cc duktape/duktape.c duktape/setjmp.c)
target_include_directories(javascript PUBLIC ./duktape)