cmake_minimum_required(VERSION 3.13.4)
project(demo)

set(WASM2BRS_DIR "../.." CACHE STRING "The wasm2brs repo directory")

# Enable many optimizations which helps reduce code size
#add_compile_options(-Ofast)

# The ignored warnings are due to the preamble.h in wasienv
add_compile_options(-Wno-macro-redefined -Wno-writable-strings -Wno-return-type)

# Any undefined functions are assumed to be imported from BrightScript
add_link_options(-Wl,--allow-undefined)

add_executable(demo main.cc)

target_include_directories(demo PRIVATE "${WASM2BRS_DIR}/include")

# Perform wasm specific optimizations (required to reduce BrightScript variables and goto/labels)
add_custom_command(TARGET demo POST_BUILD
    COMMAND "${WASM2BRS_DIR}/build/wasm2brs/third_party/binaryen/bin/wasm-opt" -g -Oz demo.wasm -o demo-opt.wasm
)

# Output the final optimized wasm file to BrightScript
add_custom_command(TARGET demo POST_BUILD
    COMMAND "${WASM2BRS_DIR}/build/wasm2brs/wasm2brs" -o demo.brs demo-opt.wasm
)
