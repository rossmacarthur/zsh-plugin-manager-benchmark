#!/usr/bin/env bash

err() {
    printf "$@"
    exit 1
}

usage() {
    cat 1>&2 <<EOF
Benchmark different plugin managers.

USAGE:
    bench.sh [FLAGS] [OPTIONS]

Options:
  -h, --help       Show this message and exit.
  -k, --kind KIND  The kind of plugin manager to benchmark.

Commands:
  update-plugins  Update the plugin manager source from plugins.txt.
  install         Benchmark the 'install' step.
  load            Benchmark the 'load' step.
EOF
}

usage_err() {
    printf "$@"
    usage
    exit 1
}

update_plugins() {
    local kind=$1

    plugins=$(cat plugins.txt)

    # Antibody
    if [ -z "$kind" ] || [ "$kind" = "antibody" ]; then
        cp plugins.txt src/antibody/plugins.txt
    fi

    # Antigen
    if [ -z "$kind" ] || [ "$kind" = "antigen" ]; then
        echo '#!/usr/bin/env zsh' > src/antigen/zshrc
        echo 'source /root/antigen.zsh' >> src/antigen/zshrc
        for plugin in $plugins; do
            echo "antigen bundle \"$plugin\"" >> src/antigen/zshrc
        done
        echo "antigen apply" >> src/antigen/zshrc
    fi

    # Sheldon
    if [ -z "$kind" ] || [ "$kind" = "sheldon" ]; then
        echo "" > src/sheldon/plugins.toml
        for plugin in $plugins; do
            echo "plugins.'$plugin'.github = '$plugin'" >> src/sheldon/plugins.toml
        done
    fi

    # Zplug
    if [ -z "$kind" ] || [ "$kind" = "zplug" ]; then
        echo '#!/usr/bin/env zsh' > src/zplug/zshrc
        echo 'export ZPLUG_HOME=/root/.zplug' >> src/zplug/zshrc
        echo 'source "$ZPLUG_HOME/init.zsh"' >> src/zplug/zshrc
        for plugin in $plugins; do
            echo "zplug \"$plugin\"" >> src/zplug/zshrc
        done
        echo '! zplug check --verbose && zplug install' >> src/zplug/zshrc
        echo 'zplug load --verbose' >> src/zplug/zshrc
    fi
}

clean_command() {
    case $1 in
        antibody )
            echo 'rm -rf /root/.cache/antibody'
            ;;
        antigen )
            echo 'rm -rf /root/.antigen'
            ;;
        sheldon )
            echo 'rm -rf /root/.sheldon/repos /root/.sheldon/plugins.lock'
            ;;
        zplug )
            echo 'rm -rf /root/.zplug/repos'
            ;;
        * )
            err "unknown kind '%s'" $kind
    esac
}

docker_args() {
    case $1 in
        antibody )
            echo "-v $PWD/src/antibody/plugins.txt:/root/.antibody/plugins.txt"
            ;;
        sheldon )
            echo "-v $PWD/src/sheldon/plugins.toml:/root/.sheldon/plugins.toml"
            ;;
        * )
            ;;
    esac
}

build_docker_image() {
    docker build --tag zsh-plugin-manager-benchmark . >/dev/null
}

docker_run() {
    local kind=$1; shift
    local args=$(docker_args "$kind")
    docker run \
        $args \
        -v "$PWD/results:/target" \
        -v "$PWD/src/$kind/zshrc:/root/.zshrc" \
        -it zsh-plugin-manager-benchmark \
        "$@"
}

bench_install() {
    local kind=$1

    update_plugins "$kind" || return 1
    build_docker_image || return 1

    for k in antibody antigen sheldon zplug; do
        if [ -z "$kind" ] || [ "$k" = "$kind" ]; then
            docker_run "$k" \
                hyperfine \
                --prepare "$(clean_command "$k")" \
                --warmup 3 \
                --time-unit millisecond \
                --export-json "/target/results-install-$k.json" \
                'zsh -ic exit'
        fi
    done
}

bench_load() {
    local kind=$1

    update_plugins "$kind" || return 1
    build_docker_image || return 1

    for k in antibody antigen sheldon zplug; do
        if [ -z "$kind" ] || [ "$k" = "$kind" ]; then
            docker_run "$k" \
                hyperfine \
                --warmup 3 \
                --time-unit millisecond \
                --export-json "/target/results-load-$k.json" \
                'zsh -ic exit'
        fi
    done
}

main() {
    local cmd kind

    while test $# -gt 0; do
        case $1 in
            --help | -h)
                usage
                exit 0
                ;;
            --kind | -k)
                shift
                if [ -z "$1" ]; then
                    usage_err "Error: --kind option requires an argument\n\n"
                fi
                kind=$1
                ;;
            update-plugins | install | load )
                if [ -z "$cmd" ]; then
                    cmd=$1
                else
                    usage_err "Error: unrecognized command line argument '%s'\n\n" "$1"
                fi
                ;;
            *)
                usage_err "Error: unrecognized command line argument '%s'\n\n" "$1"
                ;;
        esac
        shift
    done

    case $cmd in
        "" )
            usage
            ;;
        update-plugins )
            update_plugins "$kind"
            ;;
        install )
            bench_install "$kind"
            ;;
        load )
            bench_load "$kind"
            ;;
        * )
            err "unreachable\n"
            ;;
    esac
}

main "$@"
