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

RUN groupadd -g 1000 group && useradd -g 1000 -u 1000 -ms /bin/bash user
USER user
WORKDIR /home/user

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD echo "No command specified"