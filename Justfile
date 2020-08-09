# Show this message and exit.
help:
    @just --list

# Build a base image to use for benchmarking.
build-base:
    docker build --tag zsh-plugin-manager-benchmark .

_docker-args KIND:
    #!/usr/bin/env bash
    case {{ KIND }} in
        sheldon )
            echo "-v $PWD/src/sheldon/plugins.toml:/root/.sheldon/plugins.toml"
            ;;
        * )
            ;;
    esac

# Run a command in the Docker container.
run KIND +ARGS:
    #!/usr/bin/env bash -x
    docker run \
        $(just _docker-args {{ KIND }}) \
        -v $PWD/src/{{ KIND }}/zshrc:/root/.zshrc \
        -it zsh-plugin-manager-benchmark \
        {{ ARGS }}

# Benchmark the given type of plugin manager.
bench KIND: build-base
    just run {{ KIND }} 'hyperfine --warmup 3 "zsh -ic exit"'

# Open a (Docker) shell using the given type of plugin manager.
shell KIND: build-base
    just run {{ KIND }} zsh
