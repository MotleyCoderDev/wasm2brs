.PHONY: all doom files run_test

FORCE: ;

all: build/wasm2brs/wasm2brs files doom test/bin/index.js

build/wasm2brs/wasm2brs: build/wasm2brs/Makefile FORCE
	GNUMAKEFLAGS=--no-print-directory cmake --build ./build/wasm2brs --parallel

build/wasm2brs/Makefile:
	mkdir -p build/wasm2brs
	cd build/wasm2brs && cmake ../..

test/bin/index.js: test/index.ts test/node_modules
	cd test && rm -rf bin && npm run build

test/node_modules: test/package.json
	cd test && npm install && touch node_modules

run_test: test/bin/index.js build/wasm2brs/wasm2brs
	cd test && node bin/index.js $(ARGS)

doom: build/doom/Makefile build/wasm2brs/wasm2brs
	GNUMAKEFLAGS=--no-print-directory cmake --build ./build/doom --parallel
	./build/wasm2brs/third_party/binaryen/bin/wasm-opt -g -O4 ./build/doom/doom.wasm -o ./build/doom/doom-opt.wasm
	./build/wasm2brs/wasm2brs -o project/source/test.wasm.brs ./build/doom/doom-opt.wasm
	cp samples/doom/doom.brs project/source/test.cases.brs
	cp samples/doom/doom1.wad project/source/doom1.wad

files: build/files/files-wasm.brs
	cp build/files/files-wasm.brs project/source/test.wasm.brs
	cp samples/files/files.brs project/source/test.cases.brs

build/files/files-wasm.brs: samples/files/files.cc build/wasm2brs/wasm2brs
	mkdir -p build/files
	wasic++ -g -Oz samples/files/files.cc -o ./build/files/files.wasm
	./build/wasm2brs/third_party/binaryen/bin/wasm-opt -g -Oz ./build/files/files.wasm -o ./build/files/files-opt.wasm
	./build/wasm2brs/wasm2brs -o build/files/files-wasm.brs ./build/files/files-opt.wasm

build/doom/Makefile:
	mkdir -p build/doom
	cd build/doom && wasimake cmake ../../samples/doom