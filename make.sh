#!/bin/bash
set -e
cd "$(dirname "$0")"
docker build -q -t wasm2brs ./docker
docker run -t -v `pwd`:`pwd` -w `pwd` -u `id -u`:`id -g` --network host --rm wasm2brs make "$@"