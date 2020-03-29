suppressPackageStartupMessages({
  require(data.table)
  require(jsonlite)
})

.args <- if (interactive()) c(
  "~/Dropbox/COVIDSA/outputs/bpsR2/SouthAfrica-bpsamples.rds",
  "inputs/hosp.json",
   "~/Dropbox/COVIDSA/outputs/hospR2/SouthAfrica-hosp.rds"
) else commandArgs(trailingOnly = TRUE)

incidence <- readRDS(.args[1])
params <- read_json(.args[2], simplifyVector = TRUE)

ridentity <- function(n, value) rep(value, n)
rsample <- function(
  n, options, prob = NULL, replace = TRUE
) sample(options, n, replace, prob)

getpars <- function(distro_from_json) with(distro_from_json, dynGet(
  "pars", ifnotfound = {
    transformfun <- switch(type, lnorm = function(meanX, sdX) list(
      meanlog=log((meanX^2)/(sqrt(sdX^2 + meanX^2))),
      sdlog=sqrt(log(1 + (sdX/meanX)^2))
    ))
    do.call(transformfun, upars)
  }
))

getr <- function(distro_from_json) with(distro_from_json, {
  rfun <- get(sprintf("r%s", type))
  funpars <- getpars(distro_from_json)
  function(n) do.call(rfun, c(list(n=n), funpars))
})

r2admit <- getr(params$onset2admit)
radmit2icu <- getr(params$admit2icu)
ricu2exit <- getr(params$icu2exit)
radmit2discharge <- getr(params$admit2discharge)
routcome <- getr(params$outcome)

# c(mild increment, ward increment, icu increment)
eventmap <- list(
  admit = list(1L,0L),
  discharge = list(-1L,0L),
  icu = list(-1L,1L),
  exit = list(0L,-1L)
)

#' steps:
#'  1. draw outcome
#'  2. if nonhosp, break
#'  3. if ward, draw admit2discharge, break
#'  4. if icu, draw admit2icu, icu2recovery, recovery2discharge, break
#'  5. if death, draw admit2icu, icu2death
cutoff <- incidence[,.(maxday=max(day)),by=sample_id]

extendevents <- function(dt) dt[, c('ward','icu') := eventmap[[event]], by=event]

wardevents <- extendevents(data.table(event = c("admit", "discharge")))
icuevents <- extendevents(data.table(event = c("admit", "icu", "exit")))
nonevents <- data.table(event = character(0), ward = integer(0), icu = integer(0))

allcrunch <- rbindlist(lapply(incidence[,unique(sample_id)], function(sid) {
  out.dt <- incidence[sample_id == sid, {
    outcomes <- routcome(N)
    res <- rbindlist(lapply(
      seq_along(outcomes), function(ind) switch(outcomes[ind], nonhosp = nonevents, ward = copy(wardevents), icu = copy(icuevents)
    )[, id := ind ]))
  }, keyby=.(sample_id, day)]
  out.dt[event == "admit", etime := r2admit(.N) ]
  out.dt[event == "discharge", etime := radmit2discharge(.N) ]
  out.dt[event == "icu", etime := radmit2icu(.N) ]
  out.dt[event == "exit", etime := ricu2exit(.N) ]
  out.dt[, eday := floor(day + cumsum(etime)), by=.(sample_id, day, id)]
  crunch <- out.dt[cutoff, on=.(sample_id)][eday < maxday,.(ward=sum(ward), icu=sum(icu)), keyby=.(sample_id, eday)]
#  cat(sid," complete\n")
  return(crunch)
}))

ret.dt <- allcrunch[
  order(eday), .(
    day = eday,
    cur.ward=cumsum(ward), cur.icu=cumsum(icu)
  ),
  keyby = sample_id
]

#' @examples 
#' require(ggplot2)
#' mlt <- melt(ret.dt, id.vars = c('sample_id','day'))
#' ggplot(mlt) + aes(day, value, group = sample_id) +
#'  facet_grid(variable ~ ., scale = 'free_y') +
#'  geom_line(alpha = 0.05) +
#'  theme_minimal()

saveRDS(ret.dt, tail(.args, 1))
