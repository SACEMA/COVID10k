suppressPackageStartupMessages({
  require(ggplot2)
  require(data.table)
  require(cowplot)
})

.args <- if (interactive()) c(
  "~/Dropbox/COVIDSA/outputs/R2quantiles.rds",
  "~/Dropbox/COVIDSA/figs/estimate-all.jpg"
) else commandArgs(trailingOnly = TRUE)

# fns <- grep("SouthAfrica", list.files(.args[1], "-quantiles\\.rds$"), value = TRUE, invert = TRUE)
# 
# SAqs.dt <- readRDS(.args[2])[, country := "SouthAfrica" ]

qs.dt <- readRDS(.args[1])

# day0s <- rbindlist(lapply(list.files(.args[1], "-params\\.json$"), function(fn) {
#   cty <- gsub("^(.+)-.+$", "\\1", fn)
#   res <- list(date = as.Date(read_json(sprintf("%s/%s",.args[1],fn))$day0))
#   res$country <- cty
#   res
# }))

fwrite(qs.dt, gsub("\\.[^\\.]+$",".csv", tail(.args, 1)))

bars <- qs.dt
bars[country == "UnitedRepublicofTanzania", country := "Tanzania"]
bars[country == "CentralAfricanRepublic", country := "Cen. African Rep."]

bars[, country := gsub("^([^ ]+)([A-Z])", "\\1 \\2", country)]
bars[, country := gsub("^([^ ]+)([A-Z])", "\\1 \\2", country)]
bars[, country := gsub("^([^ ]+)([A-Z])", "\\1 \\2", country)]
bars[, country := gsub("([^ ])of", "\\1 of", country)]
bars[, country := gsub("([^ ])the", "\\1 the", country)]
bars[country == "Coted Ivoire", country := "Cote d'Ivoire"]
bars[country == "Democratic Republic of the Congo", country := "DR Congo"]


lvls <- bars[value == 1000][order(med), country]
bars.p <- copy(bars)[, cty := factor(country, levels = rev(lvls), ordered = TRUE)]

shft <- 0.1

brks <- c(1, seq(90, by=3, length.out = 8), 1000)

lbref <- as.Date("2020-01-01") + brks
lbls <- c(
  sprintf("by %s", format(lbref[2],"%b %d")),
  sprintf("%s-%s", format(head(lbref[-1], -2)+1,"%b %d"), format(head(lbref[-c(1,2)], -1),"%b %d")),
  sprintf("after %s", format(tail(lbref, 2)[1], "%b %d"))
)

bars.p[value == 1000,
  div := cut(as.numeric(med-as.Date("2020-01-01")), brks)
]

p <- ggplot(bars.p) + aes() +
  geom_segment(
    aes(y=as.integer(cty)-shft, yend=as.integer(cty)-shft, x=lo, xend=hi),
    data = function(dt) dt[value == 10000],
    size = 2.5, alpha = 0.9, color = "grey"
  ) +
  geom_segment(
    aes(y=as.integer(cty)+shft, yend=as.integer(cty)+shft, x=lo, xend=hi, color=div),
    data = function(dt) dt[value == 1000],
    size = 2.5, alpha = 0.9
  ) +
  geom_segment(
    aes(y=as.integer(cty)-shft, yend=as.integer(cty)-shft, x=lo.lo, xend=hi.hi),
    data = function(dt) dt[value == 10000],
    size = 1, alpha = 0.5, color = "grey"
  ) +
  geom_segment(
    aes(y=as.integer(cty)+shft, yend=as.integer(cty)+shft, x=lo.lo, xend=hi.hi, color=div),
    data = function(dt) dt[value == 1000],
    size = 1, alpha = 0.5
  ) +
  geom_vline(aes(xintercept=as.Date("2020-03-25")), color = "red", linetype = "dashed", alpha = 0.5) +
  coord_cartesian(xlim=as.Date(c("2020-03-15", "2020-06-01"))) +
  scale_x_date("Date", breaks = as.Date(c(
    "2020-03-15", "2020-04-01", "2020-04-15", "2020-05-01",
    "2020-05-15", "2020-06-01"
  )), date_labels = "%d %b") +
  scale_y_continuous(breaks = 1:length(lvls), labels = rev(lvls), expand = expansion(add=0.5)) +
  scale_color_brewer(
    "Median date\nof 1000 cases",
    palette = "YlOrRd", direction = -1,
    labels = lbls
    #labels = function(b) sprintf("%s cases", b),
    #aesthetics = c("color", "fill")
  ) +
  theme_minimal() + theme(
    axis.title.y = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = c(.9, 1),
    legend.justification = c(1, 1)
  )

save_plot(tail(.args, 1), p,
  base_height = 6.7, base_asp = 7.5/8,
  nrow=1, ncol=1,
  dpi=600
)
