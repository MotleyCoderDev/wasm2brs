# These rules aren't backed by files and will always run
.PHONY: all wasm2brs doom files run_test

# This rule must be first so it runs when you don't specify a target
all: build/wasm2brs/wasm2brs files doom test/bin/index.js

# Because we call into cmake, we don't know whether some rules need to be updated
# For example in rule build/wasm2brs/wasm2brs we don't know if brs-writer.cc changed
# unless we run the cmake every time. The solution is to FORCE cmake to run every time
# by using an empty rule. This also has the advantage over a PHONY rule that anyone
# who depends on a rule that uses FORCE (e.g. build/wasm2brs/wasm2brs) is not themselves
# forced to rebuild each time, but they would if we used a PHONY.
FORCE: ;

# --- wasm2brs
build/wasm2brs/wasm2brs: build/wasm2brs/Makefile FORCE
	GNUMAKEFLAGS=--no-print-directory cmake --build ./build/wasm2brs --parallel

build/wasm2brs/Makefile:
	mkdir -p build/wasm2brs
	cd build/wasm2brs && cmake ../..

# --- test
test/bin/index.js: test/index.ts test/node_modules
	cd test && rm -rf bin && npm run build

test/node_modules: test/package.json
	cd test && npm install && touch node_modules

run_test: test/bin/index.js build/wasm2brs/wasm2brs
	cd test && node bin/index.js $(ARGS)

# --- doom
doom: build/doom/doom-wasm.brs
	cp build/doom/doom-wasm.brs project/source/test.wasm.brs
	cp samples/doom/doom.brs project/source/test.cases.brs
	cp samples/doom/doom1.wad project/source/doom1.wad

build/doom/doom-wasm.brs: build/doom/doom.wasm build/wasm2brs/wasm2brs
	./build/wasm2brs/third_party/binaryen/bin/wasm-opt -g -O4 ./build/doom/doom.wasm -o ./build/doom/doom-opt.wasm
	./build/wasm2brs/wasm2brs -o build/doom/doom-wasm.brs ./build/doom/doom-opt.wasm

build/doom/doom.wasm: build/doom/Makefile FORCE
	GNUMAKEFLAGS=--no-print-directory cmake --build ./build/doom --parallel

build/doom/Makefile:
	mkdir -p build/doom
	cd build/doom && wasimake cmake ../../samples/doom

# --- files
files: build/files/files-wasm.brs
	cp build/files/files-wasm.brs project/source/test.wasm.brs
	cp samples/files/files.brs project/source/test.cases.brs

build/files/files-wasm.brs: build/files/files.wasm build/wasm2brs/wasm2brs
	./build/wasm2brs/third_party/binaryen/bin/wasm-opt -g -Oz ./build/files/files.wasm -o ./build/files/files-opt.wasm
	./build/wasm2brs/wasm2brs -o build/files/files-wasm.brs ./build/files/files-opt.wasm

build/files/files.wasm: samples/files/files.cc
	mkdir -p build/files
	wasic++ -g -Oz samples/files/files.cc -o ./build/files/files.wasm
