cmake_minimum_required(VERSION 3.13.4)
project(demo)

set(CMAKE_C_FLAGS   "-Oz -Ofast -Wl,--allow-undefined")
set(CMAKE_CXX_FLAGS "-Oz -Ofast -Wl,--allow-undefined")

add_executable(demo main.cc)

target_include_directories(demo PRIVATE ../../include)
