
# Stacking for multimodal Bayesian posterior distributions

This repository includes a modified version of [the code for the Cauchy mixture examples (Yao, 2020)](https://github.com/yao-yl/Multimodal-stacking-code/blob/master/chain_stacking.R) from the following paper:

> Yuling Yao, Aki Vehtari and Andrew Gelman (2020)  
[Stacking for Non-mixing Bayesian Computations: The Curse and Blessing of Multimodal Posteriors](http://www.stat.columbia.edu/~gelman/research/unpublished/2006.12335.pdf)

As an update to the [the original code (Yao, 2020)](https://github.com/yao-yl/Multimodal-stacking-code/blob/master/chain_stacking.R), this modified version uses:  
  - [`docker`](https://www.docker.com/) to isolate system dependencies and provide portability
  - [`renv`](https://rstudio.github.io/renv/) to pin package versions
  - RStudio Package Manager ([RSPM](https://packagemanager.rstudio.com)) to access pre-compiled packages for faster installs
  - command line arguments via [`docopt`](https://github.com/docopt/docopt.R) to have the flexibility to repeat the stacking process with custom parameters

## Stacking examples for bimodal Cauchy mixtures

Build a docker image:  
  
```sh
> docker build -t stack:test . 2> build.log
```

### Equal weights example

Run a docker container with default arguments, which represent the Cauchy mixtures example with **equal** weights in [Yao et al. (2020)](http://www.stat.columbia.edu/~gelman/research/unpublished/2006.12335.pdf):

```sh
> docker run --rm stack:test

  Fitting 'cauchy.stan' with 8 chains and a seed of 100 ...
  R-hat for 'cauchy.stan': 1.64.
  Stacking using approximate LOO-CV ...
    chains: 8
    data points: 100
    posterior draws: 1000
    optimizer: 'stacking_opt.stan'
    lambda: 1.0001
    maximum iterations: 1e+05
  Stacking completed in 46.44 secs.
  Total positive mass using weighted samples: 0.52.
  Total positive mass using quasi Monte Carlo: 0.52.
  Pareto k diagnostics for approximate LOO-CV:
  # A tibble: 4 x 4
    invertal    interpretation count   percentage
    <chr>       <chr>          <table> <table>
  1 (-Inf, 0.5] good           800     100
  2 (0.5, 0.7]  ok               0       0
  3 (0.7, 1]    bad              0       0
  4 (1, Inf)    very bad         0       0
```

###  Unequal weights example

Run a docker container with custom arguments, which represent the Cauchy mixtures example with **unequal** weights in [Yao et al. (2020)](http://www.stat.columbia.edu/~gelman/research/unpublished/2006.12335.pdf):
  
```sh
> docker run --rm stack:test --mu -10,10 --prob 0.33 --length 100 --chains 8 --seed 100

  Fitting 'cauchy.stan' with 8 chains and a seed of 100 ...
  R-hat for 'cauchy.stan': 1.
  Stacking using approximate LOO-CV ...
    chains: 8
    data points: 100
    posterior draws: 1000
    optimizer: 'stacking_opt.stan'
    lambda: 1.0001
    maximum iterations: 1e+05
  Stacking completed in 41.51 secs.
  Total positive mass using weighted samples: 1.
  Total positive mass using quasi Monte Carlo: 1.
  Pareto k diagnostics for approximate LOO-CV:
  # A tibble: 4 x 4
    invertal    interpretation count   percentage
    <chr>       <chr>          <table> <table>
  1 (-Inf, 0.5] good           800     100
  2 (0.5, 0.7]  ok               0       0
  3 (0.7, 1]    bad              0       0
  4 (1, Inf)    very bad         0       0
```
