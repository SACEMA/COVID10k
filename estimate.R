suppressPackageStartupMessages({
  require(ggplot2)
})

.args <- c("bpsamples.rds", "estimate.rda")
.args <- commandArgs(trailingOnly = TRUE)

.res <- readRDS(.args[1])[, .SD[1:which.max(cumcase > 1e4)], by=sample_id]

lines.dt <- copy(.res)[, .(
  measure = "cumcases", value = cumcase, day, sample_id
)]

bars.dt <- rbind(
  .res[, .(day=day[.N], value=1e4), by=sample_id],
  .res[, .(day=day[which.max(cumcase > 1e3)], value=1e3), by=sample_id]
)[, measure := "distribution" ]

qs.dt <- bars.dt[,{
  qs <- quantile(day, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))
  names(qs) <- c("lo.lo","lo","med","hi","hi.hi")
  c(as.list(qs), measure = "cumcases")
}, by=value]

#' for a given number of cases, what is the quantile on date
#' for meeting or exceeding that number of cases

samp <- .res[,max(sample_id)]

day0 <- as.Date("2020-03-05")

p <- ggplot(lines.dt) + aes(day0+day, value, group=sample_id) +
  facet_grid(measure ~ ., switch = "y", scales = "free_y", labeller = labeller(
    measure=c(
      cumcases="Cumulative Cases\n(Simulated Trajectories)",
      distribution="Time to Case #s\n(% Simulations)"
    )
  )) +
  geom_step(alpha=5/(1+samp)) +
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
  scale_x_date("Date") +
  scale_color_manual(
    "Case Limit",
    values = c(`1000`="goldenrod", `10000`="firebrick"),
    aesthetics = c("color", "fill")
  ) +
  theme_minimal() + theme(
    axis.title.y = element_blank(),
    strip.placement = "outside"
  )

save(list=ls(), file=tail(.args, 1))
