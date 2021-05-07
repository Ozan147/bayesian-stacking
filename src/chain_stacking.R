
## Original code by Yuling Yao
## source: https://github.com/yao-yl/Multimodal-stacking-code/blob/master/chain_stacking.R

## Updated by Ozan Adiguzel

suppressPackageStartupMessages({
  library(loo)
  library(rstan)
})

options(mc.cores = parallel::detectCores())

args <- docopt::docopt(
  doc = "
    Bimodal Stacking - Cauchy Mixture Example
    
    Usage:
      train.R [-m=<m> -p=<p> -l=<l> -c=<c> -r=<r>]

    Options:
      -m --mu=<m>           Location [default: -10,10]
      -p --prob=<p>         Mixture probability [default: 0.5]
      -l --length=<l>       Data length [default: 100]
      -c --chains=<c>       Number of chains [default: 8]
      -r --seed=<r>         Seed [default: 100]
  "
)

mu <- as.double(strsplit(args$mu, ",")[[1]])
prob <- as.double(args$prob)
n <- as.integer(args$length)
chains <- as.integer(args$chains)
seed <- as.integer(args$seed)

if(any(is.na(c(mu, sigma, prob, n, chains, seed)))) {
  stop(
    glue::glue("
      All arguments should be numeric
        mu: {mu}
        prob: {prob}
        n: {n}
        chains: {chains}
        seed: {seed}
    \n")
  )
}

if (length(mu) != 2) {
  stop(glue::glue("Location (mu) should be of length 2. Input: {mu}. \n"))
}

set.seed(seed)

y <- c(
  rcauchy(floor(n * prob), mu[1], 1),
  rcauchy(ceiling(n * (1 - prob)), mu[2], 1)
)

glue::glue("Fitting 'cauchy.stan' with {chains} chains and a seed of {seed} ... \n")
stan_fit <- suppressWarnings( 
  rstan::stan(
    file = "cauchy.stan",
    data = list(N = n, y = y),
    chains = chains,
    seed = seed,
    refresh = 0
  )
)

mu_sample <- rstan::extract(object = stan_fit, pars = "mu", permuted = FALSE)[,,]

log_likelihood <- rstan::extract(
  object = stan_fit,
  pars = "log_lik",
  permuted = FALSE,
  inc_warmup = FALSE
)

r_hat <- rstan::Rhat(mu_sample)
glue::glue("R-hat for 'cauchy.stan': {round(r_hat, 2)}. \n")

chain_stack <- function(log_likelihood,
                        optimizer = "stacking_opt.stan",
                        lambda = 1.0001,
                        max_iter = 1e5,
                        progress = TRUE) {
  
  log_lik_dims <- dim(log_likelihood)
  n <- log_lik_dims[3]
  K <- log_lik_dims[2]
  S <- log_lik_dims[1]
  
  if (progress) {
    start <- Sys.time()
    cat(
      glue::glue("Stacking using approximate LOO-CV ...
        chains: {K}
        data points: {n}
        posterior draws: {S}
        optimizer: '{optimizer}'
        lambda: {lambda}
        maximum iterations: {max_iter}
      \n")
    )
  }

  loo_chain <- apply(
    X = log_likelihood,
    MARGIN = 2,
    FUN = function(chain) {
      loo_obj <- suppressWarnings(loo::loo(chain))
      c(loo_obj$pointwise[, "elpd_loo"], loo_obj$diagnostics[["pareto_k"]])
    }
  )

  loo_elpd <- loo_chain[seq(n), ]
  pareto_k <- loo_chain[-seq(n), ]

  opt_opj <- rstan::stan_model(optimizer)
  chain_weights <- rstan::optimizing(
    object = opt_opj,
    data = list(
      N = n,
      K = K,
      lpd = loo_elpd,
      lambda = rep(lambda, K),
      iter = max_iter
    )
  )[["par"]]

  if (progress) {
    time_elapsed <- round(Sys.time() - start, 2)
    cat(glue::glue("Stacking completed in {time_elapsed} {units(time_elapsed)}."), "\n")
  }

  list("chain_weights" = chain_weights, "pareto_k" = pareto_k)
  
}

mixture_draws <- function(draw,
                          weight,
                          S = NULL,
                          permutation = TRUE,
                          random_seed = seed) {
  
  draw_dims <- dim(draw)
  S <- ifelse(is.null(S), draw_dims[1], S)
  K <- draw_dims[2]
  
  if(permutation) {
    set.seed(random_seed)
    draw <- draw[sample(seq(S)), ]
  }
  
  integer_part <- floor(S * weight)
  integer_part_index <- c(0, cumsum(integer_part))
  mixture_vector <- rep(NA, S)
  for(k in 1:K){
    i1 <- 1 + integer_part_index[k]
    i2 <- integer_part_index[k + 1]
    if(i1 <= i2) {
      mixture_vector[i1:i2] <- draw[seq(integer_part[k]), k]
    }
  }
  
  mixture_vector
  
}

stack_obj <- chain_stack(log_likelihood)
chain_weights <- stack_obj[["chain_weights"]]
pareto_k <- stack_obj[["pareto_k"]]

positive_mass_w <- sum(chain_weights[which(apply(mu_sample, 2, mean) > 0)])
glue::glue("Total positive mass using weighted samples: {round(positive_mass_w, 2)}. \n")

positive_mass_mc <- mean(
  mixture_draws(draw = mu_sample, weight = chain_weights) > 0,
  na.rm = TRUE
)
glue::glue("Total positive mass using quasi Monte Carlo: {round(positive_mass_mc, 2)}. \n")

cat("Pareto k diagnostics for approximate LOO-CV:  \n")
k_cut <- table(loo:::k_cut(pareto_k))
tibble::tibble(
  invertal = names(k_cut),
  interpretation = c("good", "ok", "bad", "very bad"),
  count = k_cut,
  percentage = round(prop.table(k_cut) * 100, 2)
)
