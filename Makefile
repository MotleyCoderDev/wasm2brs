.PHONY: all run_test

all: build/wasm2brs/wasm2brs test/bin/test/index.js

build/wasm2brs/wasm2brs: CMakeLists.txt build/wasm2brs/Makefile
	rm build/wasm2brs/wasm2brs
	cmake --build ./build/wasm2brs --parallel

build/wasm2brs/Makefile:
	mkdir -p build/wasm2brs
	cd build/wasm2brs && cmake ../..

test/bin/test/index.js: test/index.ts test/node_modules
	cd test && rm -rf bin && npm run build

test/node_modules: test/package.json
	cd test && npm install && touch node_modules

run_test: test/bin/test/index.js build/wasm2brs/wasm2brs
	cd test && node bin/test/index.js $(ARGS)