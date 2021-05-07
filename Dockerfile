FROM rocker/r-ver:4.0.5

COPY /src /src
COPY renv.lock renv.lock

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libv8-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

RUN R -e " \
    install.packages( \
      'https://packagemanager.rstudio.com/all/__linux__/focal/latest/src/contrib/Archive/renv/renv_0.13.2.tar.gz', \
      repos = NULL, \
      type = 'source' \
    ); \
    renv::consent(provided = TRUE); \
    renv::restore(); \
  " \
  && rm -rf \
    /tmp/downloaded_packages/ \
    /tmp/*.rds \
    renv.lock
    
WORKDIR /src

ENTRYPOINT ["Rscript", "--vanilla", "chain_stacking.R"]
