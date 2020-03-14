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
})


.args <- c("params.json", "bpsamples.rds")
.args <- commandArgs(trailingOnly = TRUE)

#' load parameters from json file
#' TODO
params <- read_json(.args[1], simplifyVector = T)

n <- as.integer(params$samples)
i0 <- as.integer(params$initial)

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

#' create chains with bpmodels
#' TODO
res <- data.table()

#' save digested results to file

saveRDS(res, tail(.args, 1))
