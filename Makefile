docker.stamp: ./docker/Dockerfile
	docker build -t wasm2brs ./docker
	touch $@