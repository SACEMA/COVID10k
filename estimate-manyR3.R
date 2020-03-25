suppressPackageStartupMessages({
  require(ggplot2)
  require(data.table)
  require(cowplot)
  require(jsonlite)
})

.args <- c("~/Dropbox/COVIDSA/outputs")
.args <- commandArgs(trailingOnly = TRUE)

fns <- list.files(.args[1], "R3-quantiles\\.rds$")

qs.dt <- rbindlist(lapply(
  fns,
  function(fn) {
    cty <- gsub("^(.+)R3-.+$", "\\1", fn)
    readRDS(sprintf("%s/%s",.args[1],fn))[, country := cty ]
  }
))[order(country)]

day0s <- rbindlist(lapply(list.files(.args[1], "-params\\.json$"), function(fn) {
  cty <- gsub("^(.+)-.+$", "\\1", fn)
  res <- list(date = as.Date(read_json(sprintf("%s/%s",.args[1],fn))$day0))
  res$country <- cty
  res
}))

bars <- qs.dt[day0s, on=.(country)]
bars[, country := gsub("^([^ ]+)([A-Z])", "\\1 \\2", country)]
bars[, country := gsub("^([^ ]+)([A-Z])", "\\1 \\2", country)]
bars[, country := gsub("^([^ ]+)([A-Z])", "\\1 \\2", country)]
bars[, country := gsub("([^ ])of", "\\1 of", country)]
bars[, country := gsub("([^ ])the", "\\1 the", country)]
bars[country == "Coted Ivoire", country := "Cote d'Ivoire"]

lvls <- bars[value == 1000][order(lo.lo+date), country]
bars.p <- copy(bars)[, cty := factor(country, levels = rev(lvls), ordered = TRUE)]

shft <- 0.1

p <- ggplot(bars.p) + aes(color=as.character(value)) +
  geom_segment(
    aes(y=as.integer(cty)+shft, yend=as.integer(cty)+shft, x=date+lo, xend=date+hi),
    data = function(dt) dt[value == 1000],
    size = 3, alpha = 0.5
  ) +
  geom_segment(
    aes(y=as.integer(cty)+shft, yend=as.integer(cty)+shft, x=date+lo.lo, xend=date+hi.hi),
    data = function(dt) dt[value == 1000],
    size = 1, alpha = 0.5
  ) +
  geom_segment(
    aes(y=as.integer(cty)-shft, yend=as.integer(cty)-shft, x=date+lo, xend=date+hi),
    data = function(dt) dt[value == 10000],
    size = 3, alpha = 0.5
  ) +
  geom_segment(
    aes(y=as.integer(cty)-shft, yend=as.integer(cty)-shft, x=date+lo.lo, xend=date+hi.hi),
    data = function(dt) dt[value == 10000],
    size = 1, alpha = 0.5
  ) +
  geom_vline(aes(xintercept=as.Date("2020-03-25")), color = "red") +
  scale_x_date("Date", breaks = as.Date(c(
    "2020-03-15", "2020-04-01", "2020-04-15", "2020-05-01",
    "2020-05-15", "2020-06-01"
  )), date_labels = "%d %b") +
  scale_y_continuous(breaks = 1:length(lvls), labels = rev(lvls), expand = expansion(add=0.5)) +
  scale_color_manual(
    "date reporting...",
    values = c(`1000`="goldenrod", `10000`="firebrick"),
    labels = function(b) sprintf("%s cases", b),
    aesthetics = c("color", "fill")
  ) +
  theme_minimal() + theme(
    axis.title.y = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = c(.9, .9),
    legend.justification = c(1, 1)
  )

fwrite(bars, gsub("\\.png",".csv", tail(.args, 1)))

save_plot(tail(.args, 1), p, base_width = 6.5, base_height = 8, nrow=1, ncol=1)
