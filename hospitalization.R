#' estimate deaths

.args <- c(
  "hosp.json",
  sprintf("~/Dropbox/COVIDSA/outputs/%s.rds", c(
    "incidence", "hospitalized")
  )
)
.args <- commandArgs(trailingOnly = TRUE)

incidence <- readRDS(.args[2])

routcome <- function(n) sample(
  c("nonhosp","hosp","death"), n, replace = T,
  prob = c(0.5, 0.45, 0.05)
)
rhosptime <- function(n) rgamma(n, 5)
rstaytime <- function(n) rgamma(n, 5)
rdeathtime <- function(n) rgamma(n, 5)

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
