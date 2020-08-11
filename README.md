# zsh-plugin-manager-benchmark

Benchmark different Zsh plugin managers.

- Currently the following plugin managers are benchmarked.
  [antibody](https://github.com/getantibody/antibody),
  [antigen](https://github.com/zsh-users/antigen),
  [sheldon](https://github.com/rossmacarthur/sheldon),
  [zgen](https://github.com/tarjoilija/zgen),
  [zinit](https://github.com/zdharma/zinit),
  [zplug](https://github.com/zplug/zplug)

- For each plugin manager the *install time* and the *load time* is tested.
  - install time is the the time taken on the first time loading `~/.zshrc`.
  - load time is the time taken for each subsequent load of the `~/.zshrc`.

- 26 of some of the most popular plugins (by GitHub stars) listed in [Awesome
  Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins/) were used as as
  test case. See [plugins.txt](./src/plugins.txt). The plugins were extracted
  using
  [awesome-star-count](https://github.com/rossmacarthur/awesome-star-count).
- [hyperfine](https://github.com/sharkdp/hyperfine) was used as a benchmarking
  tool. All benchmarks were run on a quiet cloud VM.

## Results

The below image contains the latest *install time* results. Although install
time is not as important as load time it is probably at least worth doing the
install in parallel. From these results its very clear which plugin managers
install in parallel vs sequential.

![Install time](results/install.png)

The below image contains the latest *load time* results. This is the metric we
care about most because its about the time it takes to open a new shell until we
get a usable prompt.

![Load time](results/load.png)

### Details

Tested on
- Vultr.com
- Ubuntu 20.04
- 4 CPU
- 8192 MB RAM

Versions
- antibody v6.1.0
- antigen v2.2.2
- sheldon v0.5.3
- zgen (master @ 0b669d2)
- zinit (master @ 5e841ab3)
- zplug (master @ c4dea76)

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
pip3 install seaborn pandas
```

```sh
./chart.py install
```

or

```sh
./chart.py load
```

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.
