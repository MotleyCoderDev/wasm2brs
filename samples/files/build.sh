set -ex
SRC="`pwd`/../../project/source"
mkdir -p build
wasic++ -g -Oz files.cc -o ./build/files.wasm
../../../binaryen/bin/wasm-opt -g -Oz ./build/files.wasm -o ./build/files-opt.wasm
../../build/wasm2brs ./build/files-opt.wasm > $SRC/test.wasm.brs
cp ./files.brs $SRC/test.cases.brs