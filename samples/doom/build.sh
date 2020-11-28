set -ex
CUR="`pwd`"
SRC="`pwd`/../../project/source"
DST="`pwd`/../../testproject/source"

rm -rf build
mkdir build
cd build
wasimake cmake ..
wasimake make -j
cd ..

../../../binaryen/bin/wasm-opt -g -O4 ./build/doom.wasm -o ./build/doom-opt.wasm
../../build/wasm2brs ./build/doom-opt.wasm > $SRC/test.wasm.brs
cp ./doom.brs $SRC/test.cases.brs
rm -rf $DST/test.min.*.brs
SKIP_IDENTIFIER_REMAP=1 INPUT="$SRC/helpers.brs,$SRC/runtime.brs,$SRC/wasi.brs,$SRC/test.cases.brs,$SRC/test.wasm.brs" OUTPUT="$DST/test.min.brs" npm start --prefix ../../minifier
cp "$SRC/Main.brs" "$DST/Main.brs"
cp "$CUR/assets/doom1.wad" "$DST/doom1.wad"