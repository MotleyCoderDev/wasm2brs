cmake_minimum_required(VERSION 3.13.4)
project(javascript)

set(CMAKE_C_FLAGS_RELEASE "-Oz")
set(CMAKE_CXX_FLAGS_RELEASE "-Oz")

add_executable(javascript javascript.cc duktape/duktape.c system/setjmp.c)
target_include_directories(javascript PUBLIC ./duktape ./system)