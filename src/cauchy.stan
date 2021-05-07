
// Original code by Yuling Yao
// source: https://github.com/yao-yl/Multimodal-stacking-code/blob/master/chain_stacking.R

// Input data: a vector 'y' of length 'N'.
data {
  int<lower=0> N;
  vector[N] y;
}

// Model parameter 'mu'.
parameters {
  real mu;
}

// Output 'y' follows a cauchy distributed with location 'mu' and scale 1
model {
  y ~ cauchy(mu, 1);
}

// Log-likelihood of each data point at given location 'mu 'and scale 1
generated quantities {
  vector[N] log_lik;
  for (i in 1:N) {
    log_lik[i] = cauchy_lpdf(y[i] | mu, 1);
  }
}
