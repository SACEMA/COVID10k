#' branching process samples
suppressPackageStartupMessages({
  if(!require(bpmodels)) {
    devtools::install_github("sbfnk/bpmodels")
    if (!require(bpmodels)) stop("failed to include / install bpmodels")
  }
  if (!require(jsonlite)) {
    install.packages("jsonlite")
    if (!require(jsonlite)) stop("failed to include / install jsonlite")
  }
  if (!require(data.table)) {
    install.packages("data.table")
    if (!require(data.table)) stop("failed to include / install data.table")
  }
})


.args <- c("~/Dropbox/COVIDSA/outputs/DemocraticRepublicoftheCongo-paramsR3.json", "~/Dropbox/COVIDSA/outputs/DemocraticRepublicoftheCongo-bpsamplesR3.rds")
.args <- commandArgs(trailingOnly = TRUE)

#' load parameters from json file
#' TODO
params <- read_json(.args[1], simplifyVector = T)

chunks <- as.integer(params$chunks)
n <- as.integer(params$samples)/chunks
i0 <- as.integer(params$initial)
if (length(i0) == 1) {
  if (i0) {
    t0s <- rep(0, i0)
  } else {
    t0s <- 0
    i0 <- 1
  }
} else {
  t0s <- i0
  i0 <- length(i0)
}

getpars <- function(distro_from_json) with(distro_from_json, dynGet(
  "pars", ifnotfound = {
    transformfun <- switch(type, lnorm = function(meanX, sdX) list(
      meanlog=log((meanX^2)/(sqrt(sdX^2 + meanX^2))),
      sdlog=sqrt(log(1 + (sdX/meanX)^2))
    ))
    do.call(transformfun, upars)
  }
))

getr <- function(distro_from_json) with(distro_from_json, {
  rfun <- get(sprintf("r%s", type))
  funpars <- getpars(distro_from_json)
  function(n) do.call(rfun, c(list(n=n), funpars))
})

rserial <- getr(params$serial)
roffspring <- getr(params$offspring)

chunk <- if (chunks > 1) as.integer(gsub(".*-(\\d+)\\.rds", "\\1", tail(.args, 1))) else 1

set.seed(chunk*13 + 42)
#' create chains with bpmodels
chains <- rbindlist(lapply(1:n, function(sample_id) with(
  params, with(offspring, with(pars, 
    data.table(chain_sim(
      length(t0s), offspring = type,
      infinite = target, tree = TRUE, t0 = t0s,
      serial = rserial, mu = mu, size = size
    ))[,
      day := floor(time)
    ][,
      .N, keyby = day
    ][,
      sample_id := sample_id
    ][, cumcase := cumsum(N) ][ cumcase < target*1.5 ])))))

#' save digested results to file

saveRDS(chains, tail(.args, 1))
