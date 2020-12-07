.PHONY: all wasm2brs run_test

all: wasm2brs test/bin/index.js

wasm2brs: CMakeLists.txt build/wasm2brs/Makefile
	GNUMAKEFLAGS=--no-print-directory cmake --build ./build/wasm2brs --parallel

build/wasm2brs/Makefile:
	mkdir -p build/wasm2brs
	cd build/wasm2brs && cmake ../..

test/bin/index.js: test/index.ts test/node_modules
	cd test && rm -rf bin && npm run build

test/node_modules: test/package.json
	cd test && npm install && touch node_modules

run_test: test/bin/index.js wasm2brs
	cd test && node bin/index.js $(ARGS)