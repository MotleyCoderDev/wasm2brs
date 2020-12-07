.PHONY: all wasm2brs doom run_test

all: wasm2brs doom test/bin/index.js

wasm2brs: build/wasm2brs/Makefile
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

doom: build/doom/Makefile
	GNUMAKEFLAGS=--no-print-directory cmake --build ./build/doom --parallel

build/doom/Makefile:
	mkdir -p build/doom
	cd build/doom && wasimake cmake ../../samples/doom