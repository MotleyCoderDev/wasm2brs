set -ex
SRC="`pwd`/../../project/source"
DST="`pwd`/../../testproject/source"
./duktape.sh
./generate.sh
./build.sh
../../../binaryen/bin/wasm-opt -g -Oz --flatten --rereloop --ssa --merge-blocks -iit -Oz -aimfs=10 ./build/javascript.wasm -o ./build/javascript-opt.wasm
../../build/wasm2brs ./build/javascript-opt.wasm > $SRC/test.wasm.brs
rm -rf "$DST/test.min*.brs"
KEEP=RunTests INPUT="$SRC/helpers.brs,$SRC/runtime.brs,$SRC/wasi.brs,$SRC/test.cases.brs,$SRC/test.wasm.brs" OUTPUT="$DST/test.min.brs" npm start --prefix ../../minifier