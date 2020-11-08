mkdir -p out
clang --target=wasm32 -Wl,--allow-undefined -nostdlib -O3 main.c -o out/main.wasm
../../third_party/wabt/bin/wasm2wat out/main.wasm
../../build/wasm2brs out/main.wasm > out/main.brs