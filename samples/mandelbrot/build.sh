set -ex
SRC="`pwd`/../../project/source"
clang -Ofast --target=wasm32 -nostdlib -Wl,--no-entry mandelbrot.c -o mandelbrot.wasm
../../../binaryen/bin/wasm-opt -O4 ./mandelbrot.wasm -o ./mandelbrot-opt.wasm
../../build/wasm2brs ./mandelbrot-opt.wasm > $SRC/test.wasm.brs
