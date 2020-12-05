#!/bin/bash
set -e
docker run -v `pwd`:`pwd` -w `pwd` -u `id -u`:`id -g` --rm wasm2brs "$@"