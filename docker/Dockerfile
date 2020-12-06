FROM ubuntu:20.10

RUN apt-get update && \
    apt-get install -y \
        cmake \
        clang \
        git \
        curl \
        nodejs \
        npm \
        dumb-init

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD echo "No command specified"