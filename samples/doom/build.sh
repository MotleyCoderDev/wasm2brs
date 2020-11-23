set -ex

rm -rf build
mkdir build
cd build
wasimake cmake ..
wasimake make
cd ..

SRC="`pwd`/../../project/source"
../../../binaryen/bin/wasm-opt -O4 ./build/doom.wasm -o ./build/doom-opt.wasm
../../build/wasm2brs ./build/doom-opt.wasm > $SRC/test.wasm.brs
cp ./doom.brs $SRC/test.cases.brs