# Copyright 2020, Trevor Sundberg. See LICENSE.md
FROM ubuntu:20.10

RUN apt-get update && \
    apt-get install -y \
        cmake \
        clang \
        lld \
        git \
        curl \
        nodejs \
        npm \
        python3 \
        python3-pip \
        dumb-init

RUN ln /usr/bin/lld /usr/bin/wasm-ld

RUN groupadd -g 1000 group && useradd -g 1000 -u 1000 -ms /bin/bash user
USER user
WORKDIR /home/user

RUN curl https://raw.githubusercontent.com/wasienv/wasienv/master/install.sh |  sh

ENV WASMER_DIR="/home/user/.wasmer"
ENV WASMER_CACHE_DIR="/home/user/.wasmer/cache"
ENV PATH="/home/user/.wasmer/bin:/home/user/.wasienv/bin/:${PATH}:/home/user/.wasmer/globals/wapm_packages/.bin"

RUN curl -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/home/user/.cargo/bin:${PATH}"
RUN rustup target add wasm32-wasi
RUN cargo install cargo-wasi

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD echo "No command specified"