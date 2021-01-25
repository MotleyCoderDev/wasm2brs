#!/bin/bash
set -e
cd "$(dirname "$0")"
docker build -t wasm2brs ./docker
docker run -t -v `pwd`:`pwd` -w `pwd` -u 1000:1000 --network host --rm wasm2brs "$@"