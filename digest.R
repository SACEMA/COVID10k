suppressPackageStartupMessages({
  require(data.table)
})

.args <- c(list.files(pattern = "^bpsamples-.+rds$"), "digest.rds")
.args <- commandArgs(trailingOnly = TRUE)

.sampfls <- head(.args, -1)
.sample_offset <- readRDS(.sampfls[1])[, max(sample_id)+1]

ul <- 1e4
mar <- 1.1

.res <- rbindlist(lapply(seq_along(.sampfls), function(ind) {
  readRDS(.sampfls[ind])[,
    if (.SD[,cumcase[.N] > ul*mar]) .SD[1:which.max(cumcase > ul*mar)][, {
      pdy <- (ul*mar-cumcase[.N-1])/(cumcase[.N]-cumcase[.N-1])
      dx <- (day[.N]-day[.N-1])*pdy
      .(day=c(day[-.N], day[.N-1]+dx), cumcase=c(cumcase[-.N], ul*mar))
    }],
    by=.(sample_id = sample_id + (ind-1)*.sample_offset)
  ]
}))

lines.dt <- copy(.res)[, .(
  measure = "cumcases", value = cumcase, day, sample_id
)]

bars.dt <- rbind(
  .res[, .(day=day[which.max(cumcase > 1e4)], value=1e4), by=sample_id],
  .res[, .(day=day[which.max(cumcase > 1e3)], value=1e3), by=sample_id]
)[, measure := "distribution" ]

qs.dt <- bars.dt[,{
  qs <- quantile(day, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
  names(qs) <- c("lo.lo","lo","med","hi","hi.hi")
  c(as.list(qs), measure = "cumcases")
}, by=value]

saveRDS(lines.dt, tail(.args, 1))
saveRDS(bars.dt, gsub("(/)?\\w+\\.rds","\\1distros.rds",tail(.args, 1)))
saveRDS(qs.dt, gsub("(/)?\\w+\\.rds","\\1quantiles.rds",tail(.args, 1)))