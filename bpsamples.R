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


.args <- c("params.json", "bpsamples.rds")
.args <- commandArgs(trailingOnly = TRUE)

#' load parameters from json file
#' TODO
params <- read_json(.args[1], simplifyVector = T)

n <- as.integer(params$samples)
i0 <- as.integer(params$initial)
if (length(i0) == 1) {
  t0 <- rep(0, i0*n)
} else {
  t0 <- rep(i0, times = n)
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

set.seed(1234)
#' create chains with bpmodels
chains <- data.table(with(params, with(offspring, with(pars, chain_sim(n*i0,
  offspring = type,
  infinite = target, tree = TRUE, t0 = t0,
  serial = rserial, mu = mu, size = size
)))), key = c("n", "time"))

chains[,
  nmod := (n-1) %/% i0
][,
  day := floor(time)
]

res <- chains[, .N, keyby = .(sample_id = nmod, day)]
res[, cumcase := cumsum(N), by = sample_id]

#' save digested results to file

saveRDS(res, tail(.args, 1))
