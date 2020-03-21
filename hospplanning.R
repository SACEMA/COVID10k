#' hospitalization plotting

suppressPackageStartupMessages({
  require(data.table)
  require(ggplot2)
  require(cowplot)
})

.args <- c("~/Dropbox/COVIDSA/outputs/hospitalized.rds", "~/Dropbox/COVIDSA/outputs/hospplanning.png")
.args <- commandArgs(trailingOnly = TRUE)

sim.dt <- readRDS(.args[1])

day0 <- as.Date("2020-03-05")

mlt <- melt(sim.dt, id.vars = c('sample_id','day'))

ul <- 100
mar <- 0.5
earlyl <- round(ul*0.5)

bars.dt <- rbind(
  sim.dt[, .(day=day[which.max(cur.icu > ul)], value=ul), by=sample_id],
  sim.dt[, .(day=day[which.max(cur.icu > earlyl)], value=earlyl), by=sample_id]
)

qs.dt <- bars.dt[, {
  qs <- quantile(day, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
  names(qs) <- c("lo.lo", "lo", "md", "hi", "hi.hi")
  as.list(qs)
}, by=value]

p <- ggplot(mlt[variable == "cur.icu"]) + aes(day0 + day, value, group = sample_id) +
#  facet_grid(variable ~ ., scale = 'free_y') +
  geom_line(alpha = 0.05) +
  geom_segment(
    aes(x=day0+lo, xend=day0+hi, yend=value, color=as.character(value), group=NULL),
    data=qs.dt, size = 5, alpha = 0.5
  ) +
  geom_segment(
    aes(x=day0+lo.lo, xend=day0+hi.hi, yend=value, color=as.character(value), group=NULL),
    data=qs.dt, size = 2, alpha = 0.5
  ) +
  geom_label(
    aes(
      x=day0+(lo.lo+hi.hi)/2, y=value*.95,
      label = sprintf(
        "%s-%s (%s-%s)",
        format(lo+day0, "%d"), format(hi+day0, "%d %b"),
        format(lo.lo+day0, "%d"), format(hi.hi+day0, "%d %b")
      ),
      color=as.character(value), group=NULL
    ),
    data=qs.dt, vjust = 1, alpha = 0.75,
    show.legend = F
  ) +
  coord_cartesian(ylim=c(0,110)) +
  scale_x_date(expand = c(0,0)) +
  scale_y_continuous("COVID-19 Patients in ICU") +
  scale_color_manual(
    "reaching...",
    values = c(`50`="goldenrod", `100`="firebrick"),
    labels = function(b) sprintf("%s patients", b),
    aesthetics = c("color", "fill")
  ) +
  theme_minimal() + theme(
    axis.title.x = element_blank(),
    legend.position = c(.1, .9),
    legend.justification = c(0, 1)
  )

save_plot(tail(.args, 1), p)
