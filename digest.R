suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
})

.args <- if (interactive()) c("inputs/R2.json", paste0("~/Dropbox/COVIDSA/outputs/",c(
  "bpsR2/bpmerge.rds",
  "R2digest.rds"
))) else commandArgs(trailingOnly = TRUE)

simpars <- read_json(.args[1])
ref <- readRDS(.args[2])

# upper limit for cases considered
ul <- as.integer(simpars$target)
# margin for plotting
mar <- 1.1
earlyl <- as.integer(ul*0.1)

.res <- ref[cumcase < ul*mar]

lines.dt <- copy(.res)[, .(
  measure = "cumcases", value = cumcase
), keyby=key(.res) ]

sublines <- lines.dt[, if (max(value) >= ul) .SD[1:which.max(value >= ul)], by=.(country, sample_id)]

bars.dt <- .res[, {
  d <- if (cumcase[.N] > ul) {
    c(date[which.max(cumcase > earlyl)], date[which.max(cumcase > ul)])
  } else if (cumcase[.N] > earlyl) {
    c(date[which.max(cumcase > earlyl)], as.Date("2025-01-01"))
  } else {
    c(as.Date("2025-01-01"), as.Date("2025-01-01"))
  }
  .(day=d, value = c(earlyl, ul))
}, keyby = setdiff(key(.res), "date")]

subbars <- sublines[, {
  .(day=c(date[which.max(value > earlyl)], date[.N]), value = c(earlyl, ul))
}, keyby = setdiff(key(.res), "date")]

qs.dt <- bars.dt[,{
  qs <- quantile(as.numeric(day), probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
  names(qs) <- c("lo.lo","lo","med","hi","hi.hi")
  c(as.list(qs+as.Date("1970-01-01")), measure = "cumcases")
}, keyby=.(country, value) ]

subqs.dt <- subbars[,{
  qs <- quantile(as.numeric(day), probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
  names(qs) <- c("lo.lo","lo","med","hi","hi.hi")
  c(as.list(qs+as.Date("1970-01-01")), measure = "cumcases")
}, keyby=.(country, value) ]

saveRDS(sublines, tail(.args, 1))
saveRDS(subbars, gsub("digest","distros",tail(.args, 1)))
saveRDS(subqs.dt, gsub("digest","quantiles",tail(.args, 1)))

saveRDS(lines.dt, gsub("digest","digest-ext",tail(.args, 1)))
saveRDS(bars.dt, gsub("digest","distros-ext",tail(.args, 1)))
saveRDS(qs.dt, gsub("digest","quantiles-ext",tail(.args, 1)))


#saveRDS(.res[,.(incidence), keyby=.(sample_id, day)], gsub("(/)?\\w+\\.rds","\\1incidence.rds",tail(.args, 1)))