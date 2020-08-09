FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh

RUN curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo "sharkdp/hyperfine" --to /usr/local/bin
