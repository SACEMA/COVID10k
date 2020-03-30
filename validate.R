suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
  require(remotes)
})

remotes::install_github("eebrown/data2019nCoV", upgrade = "always")
require(data2019nCoV)

.args <- if (interactive()) c(
  "~/Dropbox/COVIDSA/outputs/va"
) else commandArgs(trailingOnly = TRUE)

tardir <- tail(.args, 1)

SR <- data.table(WHO_SR)
SRsub <- melt(
  SR[, .SD, .SDcols = grep("death|Region|\\.|Global", colnames(SR), invert = T)],
  id.vars = c("SituationReport","Date"),
  variable.name = "country"
)

targets <- SRsub[,max(value), by=country][V1 >= 1000, country]
SRslice <- SRsub[country %in% targets, .(value, measure = "cases", country, date=Date)]

saveRDS(
  SRslice,
  sprintf("%s/validation.rds", tardir)
)

slice <- SRslice[
  (value < 25) & (measure == "cases")
][
  order(date),
  .(date, detected=c(value[1], diff(value))),
  keyby = country
][, .SD[which.max(detected > 0):.N], keyby=country]

# assume all reductions are erroneous
slice[detected < 0, detected := 0]

#' @examples 
#' require(ggplot2)
#' ggplot(slice[, cdet := cumsum(detected), by=country]) + aes(x=date, y=cdet, color=country) + geom_line()
#' 

ctys <- unique(slice$country)

mods <- lapply(ctys, function(cnty) {
  subslice <- slice[country == cnty]
  list(
    locale = cnty,
    day0 = subslice[1, date]-1,
    initial = rep(0:(dim(subslice)[1]-1), subslice$detected)
  )
})

lapply(mods, function(mod) {
  write_json(mod,
             sprintf("%s/%s%s", tardir, mod$locale, "-pars.json"),
             pretty = TRUE, auto_unbox = TRUE
  )
})

