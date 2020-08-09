# zsh-plugin-manager-benchmark

Benchmark different Zsh plugin managers.

The following plugins will be used for benchmarking. They were extracted using
[awesome-star-count](https://github.com/rossmacarthur/awesome-star-count). They
are the 30 most popular plugins (by GitHub stars) listed in [Awesome Zsh
Plugins](https://github.com/unixorn/awesome-zsh-plugins/).

- [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [wting/autojump](https://github.com/wting/autojump)
- [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [StackExchange/blackbox](https://github.com/StackExchange/blackbox)
- [sobolevn/git-secret](https://github.com/sobolevn/git-secret)
- [jonmosco/kube-ps1](https://github.com/jonmosco/kube-ps1)
- [skywind3000/z.lua](https://github.com/skywind3000/z.lua)
- [b4b4r07/enhancd](https://github.com/b4b4r07/enhancd)
- [fcambus/ansiweather](https://github.com/fcambus/ansiweather)
- [chriskempson/base16-shell](https://github.com/chriskempson/base16-shell)
- [supercrabtree/k](https://github.com/supercrabtree/k)
- [zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)
- [lukechilds/zsh-nvm](https://github.com/lukechilds/zsh-nvm)
- [wfxr/forgit](https://github.com/wfxr/forgit)
- [zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)
- [larkery/zsh-histdb](https://github.com/larkery/zsh-histdb)
- [skx/sysadmin-util](https://github.com/skx/sysadmin-util)
- [iam4x/zsh-iterm-touchbar](https://github.com/iam4x/zsh-iterm-touchbar)
- [unixorn/git-extra-commands](https://github.com/unixorn/git-extra-commands)
- [MichaelAquilina/zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
- [mfaerevaag/wd](https://github.com/mfaerevaag/wd)
- [zsh-users/zaw](https://github.com/zsh-users/zaw)
- [Tarrasch/zsh-autoenv](https://github.com/Tarrasch/zsh-autoenv)
- [mafredri/zsh-async](https://github.com/mafredri/zsh-async)
- [djui/alias-tips](https://github.com/djui/alias-tips)
- [Aloxaf/fzf-tab](https://github.com/Aloxaf/fzf-tab)
- [hchbaw/auto-fu.zsh](https://github.com/hchbaw/auto-fu.zsh)
- [marzocchi/zsh-notify](https://github.com/marzocchi/zsh-notify)
- [agkozak/zsh-z](https://github.com/agkozak/zsh-z)


## _base

```sh
docker build \
    --tag zsh-plugin-manager-benchmark:base \
    --file src/_base/Dockerfile \
    src/_base
docker run \
    -v $PWD/src/sheldon/zshrc:/root/.zshrc \
    -it zsh-plugin-manager-benchmark:base \
    hyperfine --warmup 3 "zsh -ic 'exit'"
```

## sheldon

```sh
docker build \
    --tag zsh-plugin-manager-benchmark:sheldon \
    --file src/sheldon/Dockerfile \
    src/sheldon
docker run \
    -v $PWD/src/sheldon/zshrc:/root/.zshrc \
    -v $PWD/src/sheldon/root:/root/.sheldon \
    -it zsh-plugin-manager-benchmark:sheldon \
    hyperfine --warmup 3 "zsh -ic 'exit'"
```

## zplug
