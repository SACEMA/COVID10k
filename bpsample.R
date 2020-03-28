#' branching process samples
suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
  require(bpmodels)
})


.args <- if (interactive()) c(
  "~/Dropbox/COVIDSA/outputs/params/SouthAfrica-par.json", "inputs/R2.json", "~/Dropbox/COVIDSA/outputs/bpsR2/SouthAfrica-bpsamples.rds"
) else commandArgs(trailingOnly = TRUE)

#' load parameters from json file
#' TODO
params <- c(
  read_json(.args[1], simplifyVector = T),
  read_json(.args[2], simplifyVector = T)
)

n <- as.integer(params$samples)
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

set.seed(13 + 42)
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
