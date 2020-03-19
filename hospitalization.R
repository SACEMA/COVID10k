suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
})

.args <- c(
  "hosp.json",
  sprintf("~/Dropbox/COVIDSA/outputs/%s.rds", c(
    "incidence", "hospitalized"
  ))
)
.args <- commandArgs(trailingOnly = TRUE)

params <- read_json(.args[1], simplifyVector = TRUE)
incidence <- readRDS(.args[2])


ridentity <- function(n, value) rep(value, n)
rsample <- function(
  n, options, prob = NULL, replace = TRUE
) sample(options, n, replace, prob)

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

r2admit <- getr(params$onset2admit)
radmit2icu <- getr(params$admit2icu)
ricu2death <- getr(params$icu2death)
ricu2recovery <- getr(params$icu2recovery)
rrecover2discharge <- getr(params$recovery2discharge)
radmit2discharge <- getr(params$admit2discharge)
routcome <- getr(params$outcome)

# c(mild increment, ward increment, icu increment)
events <- list(
  non = c(1,0,0),
  clear = c(-1,0,0),
  admit = c(0,1,0),
  discharge = c(0,-1,0),
  icu = c(0,-1,1),
  death = c(0,0,-1),
  recover = c(0,1,-1)
)

# convert vector of outcomes into a data.table of events
# time, change in ward, change in icu
outcomemap <- function(outcomes) {
  
}

#' steps:
#'  1. draw outcome
#'  2. if nonhosp, break
#'  3. if ward, draw admit2discharge, break
#'  4. if icu, draw admit2icu, icu2recovery, recovery2discharge, break
#'  5. if death, draw admit2icu, icu2death
cutoff <- incidence[,.(maxday=max(day)),by=sample_id]

out.dt <- incidence[,{
  outcomes <- routcome(incidence)
  rel <- sort(outcomes[outcomes != "nonhosp"])
  nhosp <- length(rel)
  hosp.day <- day + floor(rhosptime(nhosp))
  ndead <- sum(rel == "death")
  leave.day <- hosp.day + floor(c(
    rdeathtime(ndead), rstaytime(nhosp-ndead)
  ))
  .(
    outcome = rel,
    hosp.day = hosp.day,
    leave.day = leave.day
  )
}, keyby=.(sample_id, day)][,
  .N,
  keyby=.(sample_id, outcome, hosp.day, leave.day)
][cutoff, on=.(sample_id)][hosp.day < maxday]

arrivals   <- out.dt[,.(N=sum(N)),by=.(sample_id, day=hosp.day)]
departures <- out.dt[cutoff, on=.(sample_id)][leave.day < maxday,.(N=sum(N)),by=.(sample_id, day=leave.day)]

events <- rbind(
  arrivals[, .(sample_id, day, inc = N)],
  departures[, .(sample_id, day, inc = -N)]
)[, .(inc=sum(inc)), keyby=.(sample_id, day)]

events[, current := cumsum(inc), by=sample_id ]

saveRDS(events, tail(.args, 1))
