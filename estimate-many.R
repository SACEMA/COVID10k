suppressPackageStartupMessages({
  require(ggplot2)
  require(data.table)
  require(cowplot)
  require(jsonlite)
})

.args <- c("~/Dropbox/COVIDSA/outputs", "~/Dropbox/COVIDSA/outputs/quantiles.rds")
.args <- commandArgs(trailingOnly = TRUE)

fns <- grep("SouthAfrica", list.files(.args[1], "-quantiles\\.rds$"), value = TRUE, invert = TRUE)

SAqs.dt <- readRDS(.args[2])[, country := "SouthAfrica" ]

qs.dt <- rbind(rbindlist(lapply(
  fns,
  function(fn) {
    cty <- gsub("^(.+)-.+$", "\\1", fn)
    readRDS(sprintf("%s/%s",.args[1],fn))[, country := cty ]
  }
)), SAqs.dt)[order(country)]

day0s <- rbindlist(lapply(list.files(.args[1], "-params\\.json$"), function(fn) {
  cty <- gsub("^(.+)-.+$", "\\1", fn)
  res <- list(date = as.Date(read_json(sprintf("%s/%s",.args[1],fn))$day0))
  res$country <- cty
  res
}))

bars <- qs.dt[day0s, on=.(country)]

p <- ggplot(bars) + aes(y=country) +
  geom_segment(
    aes(x=date+lo, xend=date+hi, yend=country, color=as.character(value), group=NULL),
    size = 5, alpha = 0.5
  ) +
  geom_segment(
    aes(x=date+lo.lo, xend=date+hi.hi, yend=country, color=as.character(value), group=NULL),
    size = 2, alpha = 0.5
  ) +
  geom_vline(aes(xintercept=as.Date("2020-03-25")), color = "red") +
  scale_x_date("Date") +
  #scale_y_continuous(breaks = c(0, 1e3, 3e3, 5e3, 7e3, 1e4)) +
  scale_color_manual(
    "reaching...",
    values = c(`1000`="goldenrod", `10000`="firebrick"),
    labels = function(b) sprintf("%s cases", b),
    aesthetics = c("color", "fill")
  ) +
  theme_minimal() + theme(
    axis.title.y = element_blank()#,
    #legend.position = c(1, 0.5),
    #legend.justification = c(1, 0.5)
  )

fwrite(bars, gsub("\\.png",".csv", tail(.args, 1)))

save_plot(tail(.args, 1), p, base_width = 6.5, base_height = 8, nrow=1, ncol=1)
