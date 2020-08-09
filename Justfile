build-base:
    docker build \
        --tag zsh-plugin-manager-benchmark:base \
        --file src/_base/Dockerfile \
        src/_base

bench-base: build-base
    docker run \
        -v $PWD/src/sheldon/zshrc:/root/.zshrc \
        -it zsh-plugin-manager-benchmark:base \
        hyperfine --warmup 3 "zsh -ic 'exit'"

build-sheldon: build-base
    docker build \
        --tag zsh-plugin-manager-benchmark:sheldon \
        --file src/sheldon/Dockerfile \
        src/sheldon

bench-sheldon: build-sheldon
    docker run \
        -v $PWD/src/sheldon/zshrc:/root/.zshrc \
        -v $PWD/src/sheldon/root:/root/.sheldon \
        -it zsh-plugin-manager-benchmark:sheldon \
        hyperfine --warmup 3 "zsh -ic 'exit'"
