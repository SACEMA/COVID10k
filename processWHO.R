suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
})

.args <- if (interactive()) { 
  c("2020-03-25", "outputs/params", "inputs/latest-WHO.rds", "-par.json")
} else commandArgs(trailingOnly = TRUE)

datelim <- as.Date(.args[1])
SR <- readRDS(.args[2])
tardir <- .args[3]
stem <- tail(.args, 1)

atleastone <- SR[date <= datelim][
  measure == "cases",
  .(any=sum(value, na.rm = T)),
  by=country
][
  any > 0, country
]

slice <- SR[
  (date <= datelim) & (country %in% atleastone) & (value < 25) & (measure == "cases")
][
  order(date),
  .(date, detected=c(value[1], diff(value))),
  keyby = country
][, .SD[which.max(detected > 0):.N], keyby=country]

# assume all reductions are erroneous
slice[detected < 0, detected := 0]

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
    sprintf("%s/%s%s", tardir, mod$locale, stem),
    pretty = TRUE, auto_unbox = TRUE
  )
})
