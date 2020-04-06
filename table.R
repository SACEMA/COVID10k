suppressPackageStartupMessages({
  require(data.table)
})

.args <- if (interactive()) sprintf("~/Dropbox/COVIDSA/outputs/figs/%s", c(
  "estimate-all.csv", "pretty.csv"
)) else commandArgs(trailingOnly = TRUE)

dt <- fread(
  .args[1],
  colClasses = c(lo.lo="Date", lo="Date", med="Date",hi="Date",hi.hi="Date")
)
dt1k <- dt[value == 1000]
dt10k <- dt[value == 10000]
fmt <- "%b %d"
refine <- function(dt) dt[,
                          .(clean=sprintf("%s-%s (%s-%s)",
                                          format(lo, fmt),
                                          format(hi, fmt),
                                          format(lo.lo, fmt),
                                          format(hi.hi, fmt)
                          )),
                          by=.(Country=country)
                          ]
tb <- refine(dt1k)[refine(dt10k), on=.(Country)]
colnames(tb)[2:3] <- c("Date of 1K Cases, 50% interval (95%)", "...10K Cases")

fwrite(tb, tail(.args, 1))
