#!/bin/bash
set -e
docker build -q -t wasm2brs ./docker
docker run -v `pwd`:`pwd` -w `pwd` -u `id -u`:`id -g` --rm wasm2brs make "$@"