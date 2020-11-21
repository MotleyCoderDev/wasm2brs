set -ex
rm -f ../../project/source/test.min.*.brs
./duktape.sh
./generate.sh
./build.sh
../../../binaryen/bin/wasm-opt --flatten --rereloop -Oz ./build/javascript.wasm -o ./build/javascript-opt.wasm
../../build/wasm2brs ./build/javascript-opt.wasm > ../../project/source/test.wasm.brs
INPUT=`pwd`/../../project/source/test.wasm.brs OUTPUT=`pwd`/../../project/source/test.min.brs npm start --prefix ../../minifier
rm ../../project/source/test.wasm.brs