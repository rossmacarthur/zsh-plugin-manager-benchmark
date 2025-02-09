FROM ubuntu:latest AS base

RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    python3 \
    zsh

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo "sharkdp/hyperfine" --to /usr/local/bin

RUN echo 'unset global_rcs' >> /etc/zshenv

# Antibody
FROM base AS antibody
RUN curl -fLsS git.io/antibody | sh -s - -b /usr/local/bin

# Antidote
FROM base AS antidote
RUN git clone --depth=1 https://github.com/mattmc3/antidote.git /root/.antidote

# Antigen
FROM base AS antigen
RUN curl -fLsS -o /root/antigen.zsh https://git.io/antigen

# Sheldon
FROM base AS sheldon
RUN curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo "rossmacarthur/sheldon" --to /usr/local/bin

# Zgen
FROM base AS zgen
RUN git clone --depth 1 https://github.com/tarjoilija/zgen /root/.zgen

# Zinit
FROM base AS zinit
RUN git clone --depth 1 https://github.com/zdharma-continuum/zinit.git /root/.zinit/bin

# Zimfw
FROM base AS zimfw
RUN curl -fsSL --create-dirs -o /root/.zim/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh

# Zgenom
FROM base AS zgenom
RUN git clone --depth 1 https://github.com/jandamm/zgenom /root/.zgenom

# Zplug
FROM base AS zplug
RUN git clone --depth 1 https://github.com/zplug/zplug /root/.zplug

# Zpm
FROM base AS zpm
RUN git clone --depth 1 https://github.com/zpm-zsh/zpm /root/.zpm
