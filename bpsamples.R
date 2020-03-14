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
params <- list()

#' create chains with bpmodels
#' TODO
res <- data.table()

#' save digested results to file

saveRDS(res, tail(.args, 1))
