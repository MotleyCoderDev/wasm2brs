cmake_minimum_required(VERSION 3.13.4)
project(cmake)

set(WASM2BRS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." CACHE STRING "The wasm2brs repo directory")

# Enable many optimizations which helps reduce code size
add_compile_options(-O3 -ffast-math)

# The ignored warnings are due to the preamble.h in wasienv
add_compile_options(-Wno-macro-redefined -Wno-writable-strings -Wno-return-type)

# Any undefined functions are assumed to be imported from BrightScript
add_link_options(-Wl,--allow-undefined)

add_executable(cmake main.cc)
set_target_properties(cmake PROPERTIES OUTPUT_NAME cmake.wasm)

target_include_directories(cmake PRIVATE "${WASM2BRS_DIR}/include")

# Perform wasm specific optimizations (required to reduce BrightScript variables and goto/labels)
add_custom_command(TARGET cmake POST_BUILD
    COMMAND "wasm-opt" -g -Oz cmake.wasm -o cmake-opt.wasm
)

# Output the final optimized wasm file to BrightScript
add_custom_command(TARGET cmake POST_BUILD
    COMMAND "${WASM2BRS_DIR}/build/wasm2brs/wasm2brs" -o cmake-wasm.out.brs cmake-opt.wasm
)
