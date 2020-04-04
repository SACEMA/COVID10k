suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
})

.args <- if (interactive()) c(
  "/Users/carlpearson/Dropbox/COVIDSA/outputs/valpars",
  "/Users/carlpearson/Dropbox/COVIDSA/outputs/bpsvalidate/bpmerge.rds"
) else commandArgs(trailingOnly = TRUE)

parsfls <- list.files(.args[1], "\\.json", full.names = TRUE)
pth <- dirname(.args[2])
tar <- basename(.args[2])

fns <- grep(tar,
  list.files(pth, "\\.rds"),
  invert = TRUE, fixed = TRUE, value = TRUE
)

ctys <- gsub("(\\w+)-.+","\\1",fns)
pars <- grep(paste(ctys, collapse = "|"), parsfls, value = T)

res <- setkey(rbindlist(mapply(function(fn, par) {
  res <- readRDS(sprintf("%s/%s",pth,fn))[,
    country := gsub("(\\w+)-.+","\\1",basename(fn))
  ]
  p <- read_json(par)
  res[,
    date := day + as.Date(p$day0)
  ][,
    .(cumcase),
    keyby=.(country, sample_id, date)
  ]
}, fn = fns, par = pars, SIMPLIFY = FALSE)), country, sample_id, date)

saveRDS(res, tail(.args, 1))