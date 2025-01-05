FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    python3 \
    zsh

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo "sharkdp/hyperfine" --to /usr/local/bin

# Antibody
RUN curl -fLsS git.io/antibody | sh -s - -b /usr/local/bin

# Antidote
RUN git clone --depth=1 https://github.com/mattmc3/antidote.git /root/.antidote

# Antigen
RUN curl -fLsS -o /root/antigen.zsh https://git.io/antigen

# Sheldon
RUN curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo "rossmacarthur/sheldon" --to /usr/local/bin

# Zgen
RUN git clone --depth 1 https://github.com/tarjoilija/zgen /root/.zgen

# Zinit
RUN mkdir -p /root/.zinit \
    && git clone --depth 1 https://github.com/zdharma-continuum/zinit.git /root/.zinit/bin

# Zimfw
RUN curl -fsSL --create-dirs -o /root/.zim/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh

# Zgenom
RUN git clone --depth 1 https://github.com/jandamm/zgenom /root/.zgenom

# Zplug
RUN git clone --depth 1 https://github.com/zplug/zplug /root/.zplug

# Zpm
RUN git clone --depth 1 https://github.com/zpm-zsh/zpm /root/.zpm

RUN echo 'unset global_rcs' >> /etc/zshenv
