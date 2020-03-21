suppressPackageStartupMessages({
  require(data.table)
})

.args <- c(
  sprintf("~/Dropbox/COVIDSA/outputs/%s.rds", c("hospitalization", "incidence")),
  "~/Dropbox/COVIDSA/outputs/hospdigest.csv"
)
.args <- commandArgs(trailingOnly = TRUE)

sim.dt <- readRDS(.args[1])
inc.dt <- readRDS(.args[2])[, .SD[-.N], keyby=sample_id][, cum.inc := cumsum(incidence), keyby=.(sample_id)]

day0 <- as.Date("2020-03-05")

sim.dt[inc.dt, on=.(sample_id, day), cum.inc := cum.inc ]

setkey(sim.dt, sample_id, day)

alldays <- data.table(expand.grid(
  sample_id = sim.dt[, unique(sample_id)],
  day=sim.dt[, {
    mn <- min(day)
    mx <- max(day)
    mn:mx
  } ]))

stretch.dt <- sim.dt[alldays, on=.(sample_id, day), roll = TRUE]

setkey(stretch.dt, sample_id, day)

#' for samples where we don't have data past a certain point
#' (because hit 10k cases early in underlying sim)
#' set the values to infinite
#' once a quantile hits infinity, we know we are out of the space
#' where data is available to estimate that quantile
stretch.dt[, c('cum.mild','cur.ward','cur.icu','cum.inc') := {
  ref <- which.max(cum.mild) # monotonically increasing
  if (ref != .N) {
    infs <- rep(Inf, .N-ref)
    .(
      c(cum.mild[1:ref], infs),
      c(cur.ward[1:ref], infs),
      c(cur.icu[1:ref], infs),
      c(cum.inc[1:ref], infs)
    )
  } else .(cum.mild, cur.ward, cur.icu, cum.inc)
}, by=sample_id]

mlt <- melt(stretch.dt, id.vars = c("sample_id", "day"))
#' TODO investigate missing 0s? shouldn't those come from t0 cases?
#' or...need to add those in?
res <- mlt[,{
  qs <- quantile(value, probs = c(0.025, 0.25, 0.5, 0.75, 0.975), na.rm = TRUE)
  names(qs) <- c('lo.lo','lo','md','hi','hi.hi')
  as.list(qs)
}, by=.(variable, day = day0+day)]

fwrite(
  res[(day <= as.Date("2020-04-01")) & variable != "cum.mild"],
  tail(.args, 1)
)
