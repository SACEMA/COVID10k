suppressPackageStartupMessages({
  require(data.table)
})

.args <- c("~/Dropbox/COVIDSA/outputs/digested.rds")
.args <- commandArgs(trailingOnly = TRUE)

tardate <- as.Date(if (is.na(.args[2])) "2020-04-01" else .args[2])

day0 <- as.Date("2020-03-05")
daytar <- as.integer(tardate - day0)

sims <- readRDS(.args[1])

cat(sprintf("on %s...\n", strptime(tardate, '%F')))
print(
  sims[ day == daytar, quantile(value, probs = c(0.025, 0.25, 0.5, 0.75, 0.975)) ]
)

# sims[, .SD[which.max(value > 60)], by=sample_id][,
#   quantile(day, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
# ]
