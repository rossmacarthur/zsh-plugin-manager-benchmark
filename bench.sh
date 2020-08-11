#!/usr/bin/env bash

# Supported types of plugin managers. ('base' is an empty .zshrc)
PLUGIN_MANAGERS="base antibody antigen sheldon zgen zinit zplug"

# Prints an error message and exits.
err() {
    printf "$@"
    exit 1
}

# Prints out the command-line usage.
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
  run             Open 'zsh' with a particular plugin manager.
EOF
}

# Prints out an error message and the usage and exits.
usage_err() {
    printf "$@"
    usage
    exit 1
}

# Outputs the command to use to reset any plugin manager state.
_prepare_install() {
    case $1 in
        base )
            ;;
        antibody )
            echo 'rm -rf /root/.cache/antibody'
            ;;
        antigen )
            echo 'rm -rf /root/.antigen'
            ;;
        sheldon )
            echo 'find /root/.sheldon -mindepth 1 -maxdepth 1 ! -name "plugins.toml" -exec rm -rf {} \;'
            ;;
        zgen )
            echo 'git -C /root/.zgen clean -dffx'
            ;;
        zinit )
            echo 'find /root/.zinit -mindepth 1 -maxdepth 1 ! -name "bin" -exec rm -rf {} \;'
            ;;
        zplug )
            echo 'rm -rf /root/.zplug/repos'
            ;;
        * )
            return 1
    esac
}

# Build a Docker container for benchmarking.
_docker_build() {
    docker build --tag zsh-plugin-manager-benchmark . >/dev/null
}

# Outputs extra arguments for the Docker run command for the given plugin manager.
_docker_args() {
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

# Runs the given command in Docker with the given plugin manager setup.
_docker_run() {
    local kind=$1; shift
    local args
    args=$(_docker_args "$kind")
    test $? -ne 0 && err "Error: failed to get Docker args for %s\n" "$kind"
    docker run \
        $args \
        -v "$PWD/results:/target" \
        -v "$PWD/src/$kind/zshrc:/root/.zshrc" \
        -it zsh-plugin-manager-benchmark \
        "$@"
}

# Updates src/ with the plugins in plugins.txt.
_update_plugins() {
    local kind=$1

    plugins=$(cat src/plugins.txt)

    # Antibody
    if [ -z "$kind" ] || [ "$kind" = "antibody" ]; then
        cp src/plugins.txt src/antibody/plugins.txt
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

    # Zgen
    if [ -z "$kind" ] || [ "$kind" = "zgen" ]; then
        echo '#!/usr/bin/env zsh' > src/zgen/zshrc
        echo 'source "/root/.zgen/zgen.zsh"' >> src/zgen/zshrc
        echo 'if ! zgen saved; then' >> src/zgen/zshrc
        for plugin in $plugins; do
            echo "  zgen load $plugin" >> src/zgen/zshrc
        done
        echo '  zgen save' >> src/zgen/zshrc
        echo 'fi' >> src/zgen/zshrc
    fi

    # Zinit
    if [ -z "$kind" ] || [ "$kind" = "zinit" ]; then
        echo '#!/usr/bin/env zsh' > src/zinit/zshrc
        echo 'source "/root/.zinit/bin/zinit.zsh"' >> src/zinit/zshrc
        echo 'autoload -Uz _zinit' >> src/zinit/zshrc
        echo '(( ${+_comps} )) && _comps[zinit]=_zinit' >> src/zinit/zshrc
        echo 'zinit for \' >> src/zinit/zshrc
        for plugin in $plugins; do
            echo "  light-mode $plugin \\" >> src/zinit/zshrc
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

# Runs the 'update-plugins' command.
command_update_plugins() {
    local kind=$1
    _update_plugins "$kind"
}

# Runs the 'install' command.
#
# This benchmarks the 'install' step for the given or all plugin managers.
command_install() {
    local kind=$1
    local prepare
    _update_plugins "$kind" || err "Error: failed to update plugins"
    _docker_build || err "Error: failed to build docker image"
    for k in $PLUGIN_MANAGERS; do
        if [ -z "$kind" ] || [ "$k" = "$kind" ]; then
            echo -e "\033[1;32mBenchmarking $k\033[0m "
            prepare=$(_prepare_install "$k")
            test $? -ne 0 && err "Error: failed to get prepare command for %s\n" "$k"
            _docker_run "$k" \
                hyperfine \
                --prepare "$prepare" \
                --warmup 3 \
                --export-json "/target/install-$k.json" \
                'zsh -ic exit'
        fi
    done
}

# Runs the 'load' command.
#
# This benchmarks the 'load' step for the given or all plugin managers.
command_load() {
    local kind=$1
    _update_plugins "$kind" || err "Error: failed to update plugins"
    _docker_build || err "Error: failed to build docker image"
    for k in $PLUGIN_MANAGERS; do
        if [ -z "$kind" ] || [ "$k" = "$kind" ]; then
            echo -e "\033[1;32mBenchmarking $k\033[0m "
            _docker_run "$k" \
                hyperfine \
                --warmup 3 \
                --export-json "/target/load-$k.json" \
                'zsh -ic exit'
        fi
    done
}

# Runs the 'run' command.
#
# This opens 'zsh' setup for the given plugin manager.
command_run() {
    local kind=$1
    [ -z "$kind" ] && err "Error: --kind is a required option for this command\n"
    _update_plugins "$kind" || err "Error: failed to update plugins"
    _docker_build || err "Error: failed to build docker image"
    _docker_run "$kind" zsh
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
                elif [[ "$PLUGIN_MANAGERS" != *"$1"* ]]; then
                    err "Error: --kind value should be one of: $PLUGIN_MANAGERS\n"
                fi
                kind=$1
                ;;
            update-plugins | install | load | run )
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
            command_update_plugins "$kind"
            ;;
        install )
            command_install "$kind"
            ;;
        load )
            command_load "$kind"
            ;;
        run )
            command_run "$kind"
            ;;
        * )
            err "unreachable\n"
            ;;
    esac
}

main "$@"
