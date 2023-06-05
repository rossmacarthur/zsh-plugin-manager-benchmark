# zsh-plugin-manager-benchmark

Benchmark different Zsh plugin managers.

### Summary

- [antibody], [antidote], [antigen], and [sheldon] all have excellent
  performance in both install time and load time.
- [zgen] and [zgenom] are on par with the above when it comes to load time, but
  don't seem to do installation in parallel.
- [zinit], [zplug] and [zpm] have notably bad load time performance.

## Features

- The following plugin managers are benchmarked:
  - [antibody] v6.1.1 (⚠️ archived)
  - [antidote] v1.8.6
  - [antigen] v2.2.2 (⚠️ unmaintained)
  - [sheldon] v0.7.3
  - [zgen] master @ 0b669d2 (⚠️ unmaintained)
  - [zgenom] main @ 2b55d9d
  - [zinit] master @ de85908f
  - [zplug] master @ ac6c2a3
  - [zpm] master @ 16d74f8
  - *If you would like to add a new plugin manager feel free to open an issue
    and/or pull request.*
- For each plugin manager the *install* time and the *load* time was tested
  - *install* time is the the time taken on the first time loading `~/.zshrc`
    until a prompt appears.
  - *load* time is the time taken for each subsequent load of the `~/.zshrc`
    until a prompt appears.
- 26 of some of the most popular plugins (by GitHub stars) listed in [Awesome
  Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins/) were used as as
  test case. See [plugins.txt](./src/plugins.txt). The plugins were extracted
  using [awesome-star-count].
- [hyperfine] was used as a benchmarking tool. All benchmarks were run on a
  quiet cloud VM.

[awesome-star-count]: https://github.com/rossmacarthur/awesome-star-count
[hyperfine]: https://github.com/sharkdp/hyperfine

[antibody]: https://github.com/getantibody/antibody
[antidote]: https://github.com/mattmc3/antidote
[antigen]: https://github.com/zsh-users/antigen
[sheldon]: https://github.com/rossmacarthur/sheldon
[zgen]: https://github.com/tarjoilija/zgen
[zgenom]: https://github.com/jandamm/zgenom
[zinit]: https://github.com/zdharma/zinit
[zplug]: https://github.com/zplug/zplug
[zpm]: https://github.com/zpm-zsh/zpm
[zsh-defer]: https://github.com/romkatv/zsh-defer

## Results

### Install time

<img alt="Install time" src="results/install.png" width="600"/>

Although install time is not as important as load time it is probably at least
worth doing the install in parallel. From these results its very clear which
plugin managers install in parallel vs sequential.

### Load time

<img alt="Load time" src="results/load.png" width="600"/>

This is the metric we care about most because its the time it takes to open a
new shell until we get a usable prompt.

**Note:** no deferred loading of plugins was done. For example: many plugin
managers can be used in conjunction with [zsh-defer]. Or [zinit] could be run
using `wait` which defers the plugin loading until after a prompt.

### Details

#### Host

- Vultr.com
- Ubuntu 22.04
- 8 vCPUs
- 16 GB RAM
- NVMe storage

## Usage

To benchmark the 'install' step run the following.
```sh
./bench.sh install
```

To benchmark the 'load' step run the following.
```sh
./bench.sh load
```

These commands will output results to `results/`. You can then create charts
from these results using the following.

First install Python dependencies.

```
pip install seaborn pandas
```

```sh
./chart.py install
```

or

```sh
./chart.py load
```

## License

This project is distributed under the terms of both the MIT license and the
Apache License (Version 2.0).

See [LICENSE-APACHE](LICENSE-APACHE) and [LICENSE-MIT](LICENSE-MIT) for details.
