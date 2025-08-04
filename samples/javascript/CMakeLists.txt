cmake_minimum_required(VERSION 3.13.4)
project(javascript)

add_compile_options(-Oz)

add_compile_options(-fwasm-exceptions)

add_compile_options(-Wno-macro-redefined -Wno-writable-strings -Wno-return-type -Wno-visibility)

add_executable(javascript javascript.cc duktape/duktape.cc)

target_link_options(javascript PRIVATE
    "-fwasm-exceptions"
    "-sSTANDALONE_WASM=1"
    "-sERROR_ON_UNDEFINED_SYMBOLS=1"
)

target_include_directories(javascript PRIVATE ./duktape ../../include)
