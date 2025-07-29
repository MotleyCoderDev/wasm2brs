# Copyright 2020, Trevor Sundberg. See LICENSE.md
cmake_minimum_required(VERSION 3.13.4)
project(WASM2BRS VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT DEFINED ENV{WABT_INCLUDE_DIR})
    message(FATAL_ERROR "WABT_INCLUDE_DIR environment variable is not defined!")
endif()
set(WABT_LIB_DIR $ENV{WABT_LIB_DIR})

if(NOT DEFINED ENV{WABT_LIB_DIR})
    message(FATAL_ERROR "WABT_LIB_DIR environment variable is not defined!")
endif()
set(WABT_INCLUDE_DIR $ENV{WABT_INCLUDE_DIR})

include_directories(${WABT_INCLUDE_DIR})

add_executable(wasm2brs src/wasm2brs.cc src/brs-writer.cc)

target_link_libraries(wasm2brs PRIVATE ${WABT_LIB_DIR}/libwabt.a)
