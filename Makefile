.PHONY: all

all: build/wasm2brs/wasm2brs

build/wasm2brs/wasm2brs: docker.stamp CMakeLists.txt build/wasm2brs/Makefile
	rm build/wasm2brs/wasm2brs
	cmake --build ./build/wasm2brs --parallel

build/wasm2brs/Makefile: docker.stamp ./build.sh
	./build.sh

test/bin/test/index.js: docker.stamp test/node_modules
	cd test && rm -rf bin && npm run build

test/node_modules: docker.stamp test/package.json
	cd test && rm -rf node_modules && npm install
