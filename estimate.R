suppressPackageStartupMessages({
  require(ggplot2)
  require(data.table)
  require(cowplot)
})

.args <- c("digested.rds", "distros.rds", "quantiles.rds")
.args <- commandArgs(trailingOnly = TRUE)

lines.dt <- readRDS(.args[1])
bars.dt <- readRDS(.args[2])
qs.dt <- readRDS(.args[3])
samp <- lines.dt[,max(sample_id)]

day0 <- as.Date("2020-03-05")

p <- ggplot(lines.dt) + aes(day0+day, value, group=sample_id) +
  facet_grid(measure ~ ., switch = "y", scales = "free_y", labeller = labeller(
    measure=c(
      cumcases="Cumulative Cases\n(Simulated Trajectories)",
      distribution="Date Reaching Threshold\n(% Simulations)"
    )
  )) +
  geom_line(alpha=5/(1+samp/10)) +
  geom_segment(
    aes(x=day0+lo, xend=day0+hi, yend=value, color=as.character(value), group=NULL),
    data=qs.dt, size = 5, alpha = 0.5
  ) +
  geom_segment(
    aes(x=day0+lo.lo, xend=day0+hi.hi, yend=value, color=as.character(value), group=NULL),
    data=qs.dt, size = 2, alpha = 0.5
  ) +
  geom_histogram(
    aes(y=stat(count)/samp*100, group = value, fill = as.character(value)
  ), data = bars.dt, binwidth = 1, position = "identity", alpha = 0.5) +
  geom_vline(
    aes(xintercept=day0+med, color=as.character(value)),
    data = copy(qs.dt)[, measure := "distribution"]
  ) +
  scale_x_date("Date") +
  #scale_y_continuous(breaks = c(0, 1e3, 3e3, 5e3, 7e3, 1e4)) +
  scale_color_manual(
    "reaching...",
    values = c(`1000`="goldenrod", `10000`="firebrick"),
    labels = function(b) sprintf("%s cases", b),
    aesthetics = c("color", "fill")
  ) +
  coord_cartesian(xlim = c(day0, day0+60), expand = FALSE) +
  theme_minimal() + theme(
    axis.title.y = element_blank(),
    strip.placement = "outside",
    legend.position = c(1, 0.5),
    legend.justification = c(1, 0.5)
  )

save_plot(tail(.args, 1), p, base_width = 5, base_height = 2.5, nrow=2, ncol=1)
