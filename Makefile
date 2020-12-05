
wasm2brs/Makefile: docker.stamp ./build.sh
	./run.sh ./build.sh

docker.stamp: ./docker/Dockerfile
	docker build -t wasm2brs ./docker
	touch $@