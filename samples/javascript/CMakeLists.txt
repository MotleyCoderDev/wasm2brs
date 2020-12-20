cmake_minimum_required(VERSION 3.13.4)
project(javascript)

add_compile_options(-Oz)

add_compile_options(-Wno-macro-redefined -Wno-writable-strings -Wno-return-type -Wno-visibility)

add_executable(javascript javascript.cc duktape/duktape.c)
target_include_directories(javascript PRIVATE ./duktape ../../include)
