set -ex
CUR="`pwd`"
SRC="`pwd`/../../project/source"

rm -rf build
mkdir build
cd build
wasimake cmake ..
wasimake make -j
cd ..

../../build/wasm2brs/third_party/binaryen/bin/wasm-opt -g -O4 ./build/doom.wasm -o ./build/doom-opt.wasm
../../build/wasm2brs/wasm2brs -o $SRC/test.wasm.brs ./build/doom-opt.wasm
cp ./doom.brs $SRC/test.cases.brs
cp "$CUR/assets/doom1.wad" "$SRC/doom1.wad"