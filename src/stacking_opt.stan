
// Original code by Yuling Yao
// source: https://github.com/yao-yl/Multimodal-stacking-code/blob/master/chain_stacking.R

data {
  int<lower=0> N;
  int<lower=0> K;
  matrix[N, K] lpd;
  vector[K] lambda;
}

transformed data{
  matrix[N, K] exp_lpd; 
  exp_lpd = exp(lpd);
}

parameters {
  simplex[K] w;
}

transformed parameters{
  vector[K] w_vec;
  w_vec =  w;
}

model {
  for (i in 1: N) {
    target += log(exp_lpd[i,] * w_vec);
  }
  w ~ dirichlet(lambda);
}
