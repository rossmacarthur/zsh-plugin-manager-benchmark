#!/usr/bin/env bash

# Supported types of plugin managers. ('base' is an empty .zshrc)
PLUGIN_MANAGERS="base antibody antidote antigen sheldon zgen zgenom zimfw zinit zplug zpm"
VERBOSE=false

# Prints an error message and exits.
err() {
    printf "$@"
    exit 1
}

# Prints out the command-line usage.
usage() {
    cat 1>&2 <<EOF
Benchmark different plugin managers

USAGE:
    bench.sh [FLAGS] [OPTIONS]

Options:
  -h, --help       Show this message and exit
  -k, --kind KIND  The kind of plugin manager to benchmark
  -v, --verbose    Enable verbose output

Commands:
  update-plugins  Update the plugin manager source from plugins.txt
  install         Benchmark the 'install' step
  load            Benchmark the 'load' step
  run             Open 'zsh' with a particular plugin manager
  versions        Output the versions of the plugin managers
EOF
}

# Prints out an error message and the usage and exits.
usage_err() {
    printf "$@"
    usage
    exit 1
}

# Updates src/ with the plugins in plugins.txt.
_update_plugins() {
    plugins=$(IFS=$'\n' cat src/plugins.txt)
    case $1 in
        antibody)
            echo "" > src/antibody/plugins.txt
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "$plugin" >> src/antibody/plugins.txt
            done
            ;;

        antidote)
            echo "" > src/antidote/zsh_plugins.txt
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                if [ "$plugin" = "wting/autojump" ]; then
                    echo "$plugin path:bin" >> src/antidote/zsh_plugins.txt
                else
                    echo "$plugin" >> src/antidote/zsh_plugins.txt
                fi
            done
            ;;

        antigen)
            echo '#!/usr/bin/env zsh' > src/antigen/zshrc
            echo 'ANTIGEN_LOG=/root/antigen.log' > src/antigen/zshrc
            echo 'source /root/antigen.zsh' >> src/antigen/zshrc
            for line in $plugins; do
                echo "antigen bundle \"$line\"" >> src/antigen/zshrc
            done
            echo "antigen apply" >> src/antigen/zshrc
            ;;

        sheldon)
            echo "" > src/sheldon/plugins.toml
            echo "shell = 'zsh'" >> src/sheldon/plugins.toml
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "plugins.'$plugin'.github = '$plugin'" >> src/sheldon/plugins.toml
            done
            ;;

        zgen)
            echo '#!/usr/bin/env zsh' > src/zgen/zshrc
            echo 'source "/root/.zgen/zgen.zsh"' >> src/zgen/zshrc
            echo 'if ! zgen saved; then' >> src/zgen/zshrc
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                branch=${branch:-master}
                echo "  zgen load $plugin \"\" $branch" >> src/zgen/zshrc
            done
            echo '  zgen save' >> src/zgen/zshrc
            echo 'fi' >> src/zgen/zshrc
            ;;

        zgenom)
            echo '#!/usr/bin/env zsh' > src/zgenom/zshrc
            echo 'export ZGEN_DIR=/root/.zgenom' >> src/zgenom/zshrc
            echo 'source "$ZGEN_DIR/zgenom.zsh"' >> src/zgenom/zshrc
            echo 'if ! zgenom saved; then' >> src/zgenom/zshrc
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "  zgenom load $plugin" >> src/zgenom/zshrc
            done
            echo '  zgenom save' >> src/zgenom/zshrc
            echo 'fi' >> src/zgenom/zshrc
            ;;

        zimfw)
            echo "" > src/zimfw/.zimrc
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "zmodule $plugin" >> src/zimfw/.zimrc
            done
            ;;

        zinit)
            echo '#!/usr/bin/env zsh' > src/zinit/zshrc
            echo 'source "/root/.zinit/bin/zinit.zsh"' >> src/zinit/zshrc
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "zinit light $plugin" >> src/zinit/zshrc
            done
            ;;

        zplug)
            echo '#!/usr/bin/env zsh' > src/zplug/zshrc
            echo 'export ZPLUG_HOME=/root/.zplug' >> src/zplug/zshrc
            echo 'source "$ZPLUG_HOME/init.zsh"' >> src/zplug/zshrc
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "zplug \"$plugin\"" >> src/zplug/zshrc
            done
            echo '! zplug check && zplug install' >> src/zplug/zshrc
            echo 'zplug load' >> src/zplug/zshrc
            ;;

        zpm)
            echo '#!/usr/bin/env zsh' > src/zpm/zshrc
            echo 'source "/root/.zpm/zpm.zsh"' >> src/zpm/zshrc
            echo 'zpm load \' >> src/zpm/zshrc
            for line in $plugins; do
                IFS="@" read -r plugin branch <<< "$line"
                echo "  ${plugin},async \\" >> src/zpm/zshrc
            done
            ;;
    esac
}

# Outputs the command to use to reset any plugin manager state.
_prepare_install() {
    case $1 in
        base )
            ;;
        antibody )
            echo 'rm -rf /root/.cache/antibody'
            ;;
        antidote )
            echo 'rm -rf /root/.cache/antidote /root/.zsh_plugins.zsh'
            ;;
        antigen )
            echo 'rm -rf /root/.antigen'
            ;;
        sheldon )
            echo 'rm -rf /root/.local/share/sheldon'
            ;;
        zgen )
            echo 'git -C /root/.zgen clean -dffx'
            ;;
        zgenom )
            echo 'git -C /root/.zgenom clean -dffx'
            ;;
        zimfw )
            echo 'mv /root/.zim/zimfw.zsh /root/zimfw.tmp; rm -rf /root/.zim/*; mv /root/zimfw.tmp /root/.zim/zimfw.zsh'
            ;;
        zinit )
            echo 'find /root/.zinit -mindepth 1 -maxdepth 1 ! -name "bin" -exec rm -rf {} +'
            ;;
        zplug )
            echo 'git -C /root/.zplug clean -dffx'
            ;;
        zpm )
            echo 'rm -rf /root/.local/share/zsh/plugins; rm -rf "${TMPDIR:-/tmp}/zsh-${UID:-user};"'
            ;;
        * )
            return 1
    esac
}

# Outputs extra arguments for the Docker run command for the given plugin manager.
_docker_args() {
    local kind=$1
    case $kind in
        antibody )
            echo "-v $PWD/src/$kind/plugins.txt:/root/.antibody/plugins.txt"
            ;;
        antidote )
            echo "-v $PWD/src/$kind/zsh_plugins.txt:/root/.zsh_plugins.txt"
            ;;
        sheldon )
            echo "-v $PWD/src/$kind/plugins.toml:/root/.config/sheldon/plugins.toml"
            ;;
        zimfw )
            echo "-v $PWD/src/$kind/.zimrc:/root/.zimrc"
            ;;
        * )
            ;;
    esac
}

# Runs the given command in Docker with the given plugin manager setup.
_docker_run() {
    local kind=$1; shift
    local args
    local tag="zsh-plugin-manager-benchmark:$kind"

    _update_plugins "$kind"

    args=$(_docker_args "$kind")
    test $? -ne 0 && err "Error: failed to get Docker args for %s\n" "$kind"

    if [ "$VERBOSE" = true ]; then
        docker build --tag "$tag" --target "$kind" . \
            || err "Error: failed to build docker image"
    else
        docker build --quiet --tag "$tag" --target "$kind" . &>/dev/null \
            || err "Error: failed to build docker image"
    fi

    docker run \
        $args \
        -v "$PWD/results:/target" \
        -v "$PWD/src/$kind/zshrc:/root/.zshrc" \
        -it "$tag" \
        "$@"
}

# Runs the 'update-plugins' command.
command_update_plugins() {
    local kind=$1
    for k in $PLUGIN_MANAGERS; do
        if [ -z "$kind" ] || [ "$k" = "$kind" ]; then
            _update_plugins "$kind"
            echo -e "Updated plugins for $k"
        fi
    done
}

# Runs the 'install' command.
#
# This benchmarks the 'install' step for the given or all plugin managers.
command_install() {
    local kind=$1
    local prepare
    _update_plugins "$kind" || err "Error: failed to update plugins"
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
    _docker_run "$kind" zsh
}

# Prints the version for the given plugin manager.
_print_version() {
    local kind=$1
    case $kind in
        antibody)
            version=$(_docker_run "$kind" antibody --version 2>&1 | awk '{print $3}')
            echo "antibody v$version"
            ;;

        antidote)
            version=$(_docker_run "$kind" zsh -ic "antidote --version" | tail -1 | awk '{print $3}')
            echo "antidote v$version"
            ;;

        antigen)
            version=$(_docker_run "$kind" zsh -c 'source /root/antigen.zsh && antigen-version' | awk '{print $2}')
            echo "antigen $version"
            ;;

        sheldon)
            version=$(_docker_run "$kind" sheldon --version | awk '{print $2; exit}')
            echo "sheldon v$version"
            ;;

        zgen)
            version=$(_docker_run "$kind" git -C /root/.zgen rev-parse --short HEAD)
            echo "zgen master @ $version"
            ;;

        zgenom)
            version=$(_docker_run "$kind" git -C /root/.zgenom rev-parse --short HEAD)
            echo "zgenom main @ $version"
            ;;

        zinit)
            version=$(_docker_run "$kind" git -C /root/.zinit/bin rev-parse --short HEAD)
            echo "zinit master @ $version"
            ;;

        zimfw)
            version=$(_docker_run "$kind" zsh -c 'export ZIM_HOME=/root/.zim; source $ZIM_HOME/zimfw.zsh version;')
            echo "zimfw v$version"
            ;;

        zplug)
            version=$(_docker_run "$kind" git -C /root/.zplug rev-parse --short HEAD)
            echo "zplug master @ $version"
            ;;

        zpm)
            version=$(_docker_run "$kind" git -C /root/.zpm rev-parse --short HEAD)
            echo "zpm master @ $version"
            ;;
    esac
}

# Runs the 'versions' command.
#
# This outputs the current version for each plugin manager.
command_versions() {
    local kind=$1
    for k in $PLUGIN_MANAGERS; do
        if [ -z "$kind" ] || [ "$k" = "$kind" ]; then
            _print_version "$k"
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
            --verbose | -v)
                VERBOSE=true
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
            update-plugins | install | load | run | versions )
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
        versions )
            command_versions "$kind"
            ;;
        * )
            err "unreachable\n"
            ;;
    esac
}

main "$@"
