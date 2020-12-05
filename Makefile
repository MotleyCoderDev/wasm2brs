build/wasm2brs/wasm2brs: docker.stamp CMakeLists.txt build/wasm2brs/Makefile
	./run.sh cmake --build ./build/wasm2brs --parallel

build/wasm2brs/Makefile: docker.stamp ./build.sh
	./run.sh ./build.sh

docker.stamp: ./docker/Dockerfile
	docker build -t wasm2brs ./docker
	touch $@