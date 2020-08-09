# Base
# --------------------------------------------------------------------------- #

build-base:
    docker build \
        --tag zsh-plugin-manager-benchmark:base \
        --file src/_base/Dockerfile \
        src/_base

bench-base: build-base
    docker run \
        -v $PWD/src/sheldon/zshrc:/root/.zshrc \
        -it zsh-plugin-manager-benchmark:base \
        hyperfine --warmup 3 "zsh --interactive -c 'exit'"

# Sheldon
# --------------------------------------------------------------------------- #

build-sheldon: build-base
    docker build \
        --tag zsh-plugin-manager-benchmark:sheldon \
        --file src/sheldon/Dockerfile \
        src/sheldon

bench-sheldon: build-sheldon
    docker run \
        -v $PWD/src/sheldon/zshrc:/root/.zshrc \
        -v $PWD/src/sheldon/plugins.toml:/root/.sheldon/plugins.toml \
        -it zsh-plugin-manager-benchmark:sheldon \
        hyperfine --warmup 3 "zsh --interactive -c 'exit'"

run-sheldon: build-sheldon
    docker run \
        -v $PWD/src/sheldon/zshrc:/root/.zshrc \
        -v $PWD/src/sheldon/plugins.toml:/root/.sheldon/plugins.toml \
        -it zsh-plugin-manager-benchmark:sheldon \
        zsh

# Zplug
# --------------------------------------------------------------------------- #

build-zplug: build-base
    docker build \
        --tag zsh-plugin-manager-benchmark:zplug \
        --file src/zplug/Dockerfile \
        src/zplug

bench-zplug: build-zplug
    docker run \
        -v $PWD/src/zplug/zshrc:/root/.zshrc \
        -it zsh-plugin-manager-benchmark:zplug \
        hyperfine --warmup 3 "zsh --interactive -c 'exit'"

run-zplug: build-zplug
    docker run \
        -v $PWD/src/zplug/zshrc:/root/.zshrc \
        -it zsh-plugin-manager-benchmark:zplug \
        zsh
