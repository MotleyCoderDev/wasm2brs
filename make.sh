#!/bin/bash
set -e
docker build -q -t wasm2brs ./docker
docker run -t -v `pwd`:`pwd` -w `pwd` -u `id -u`:`id -g` --network host --rm wasm2brs make "$@"