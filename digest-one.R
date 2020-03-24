suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
})

.args <- c("~/Dropbox/COVIDSA/outputs/Algeria-params.json", "~/Dropbox/COVIDSA/outputs/Algeria-bpsamples.rds")
.args <- commandArgs(trailingOnly = TRUE)

simpars <- read_json(.args[1])
sample_file <- readRDS(.args[2])


# upper limit for cases considered
ul <- as.integer(simpars$target)
# margin for plotting
mar <- 1.1
earlyl <- as.integer(ul*0.1)

.res <- sample_file[,
    if (.SD[,cumcase[.N] > ul*mar]) .SD[1:which.max(cumcase > ul*mar)][, {
      endcases <- N[.N]
      pdy <- (ul*mar-cumcase[.N-1])/endcases
      dx <- (day[.N]-day[.N-1])*pdy
      .(
        day = c(day[-.N], day[.N-1]+dx),
        cumcase = c(cumcase[-.N], ul*mar),
        incidence = c(N[-.N], ul*mar-cumcase[.N-1])
      )
    }],
    by=sample_id
  ]

lines.dt <- copy(.res)[, .(
  measure = "cumcases", value = cumcase, day, sample_id
)]

bars.dt <- rbind(
  .res[, .(day=day[which.max(cumcase > ul)], value=ul), by=sample_id],
  .res[, .(day=day[which.max(cumcase > earlyl)], value=earlyl), by=sample_id]
)[, measure := "distribution" ]

qs.dt <- bars.dt[,{
  qs <- quantile(day, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
  names(qs) <- c("lo.lo","lo","med","hi","hi.hi")
  c(as.list(qs), measure = "cumcases")
}, by=value]

saveRDS(lines.dt, tail(.args, 1))
saveRDS(bars.dt, gsub("(/)?\\w+\\.rds","\\1distros.rds",tail(.args, 1)))
saveRDS(qs.dt, gsub("(/)?\\w+\\.rds","\\1quantiles.rds",tail(.args, 1)))
saveRDS(.res[,.(incidence), keyby=.(sample_id, day)], gsub("(/)?\\w+\\.rds","\\1incidence.rds",tail(.args, 1)))