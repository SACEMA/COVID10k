suppressPackageStartupMessages({
  require(data2019nCoV)
  require(data.table)
  require(jsonlite)
})

.args <- if (interactive()) { 
  c("template-params.json", "somedir/some-pars.json")
} else commandArgs(trailingOnly = TRUE)

tardir <- dirname(tail(.args, 1))

SRwide <- data.table(WHO_SR)

#' @examples troubleshooting
#' for (col in colnames(SRwide)) {
#'   if (class(SRwide[[col]])!="integer") print(sprintf("%s : %s", col, class(SRwide[[col]])))
#' }

SRwide$`RA.China` <- SRwide$`RA.Regional` <- SRwide$`RA.Global` <- NULL

allwhoSRs <- melt(SRwide, id.vars = c('SituationReport','Date'), variable.factor = F)

# drops <- c(
#   grep("China", unique(allwhoSRs$variable), value = T),
#   grep("deaths", unique(allwhoSRs$variable), value = T)
# )

start_ind <- which(unique(allwhoSRs$variable) == "Region.EasternMediterranean")+1
end_ind <- which(unique(allwhoSRs$variable) == "Region.African")-1
adds <- c("Sudan","Somalia","Djibouti","Tunisia","Morocco","Egypt")

tarctys <- c(unique(allwhoSRs$variable)[start_ind:end_ind], adds)

atleastone <- allwhoSRs[variable %in% tarctys, .(any=sum(value, na.rm = T)), by=variable][any > 0, variable]

# outbreak_constraint <- function(R, k) uniroot(function(p, R, k) { (1+(R/k)*p)^(-k)-1+p }, c(1e-6, 1-1e-6), R=R, k=k)$root

slice <- allwhoSRs[(variable %in% atleastone) & (value < 25)][
  order(Date),
  .(detected=c(value[1], diff(value)), date=as.Date(Date)),
  keyby=.(variable)
][, .SD[which.max(detected > 0):.N], keyby=.(variable)]

slice[detected < 0, detected := 0] # assume all reductions are erroneous

#' @examples 
#' slice[,.(sum(detected), date[.N]), by=variable]

ctys <- unique(slice$variable)

mods <- lapply(ctys, function(cnty) {
  subslice <- slice[variable == cnty]
  list(
    day0=subslice[1, date]-1,
    initial = rep(0:(dim(subslice)[1]-1), subslice$detected)
  )
})

names(mods) <- ctys

refpars <- read_json(.args[1], simplifyVector = TRUE)

lapply(ctys, function(nm) {
  cppars <- refpars
  cppars[["locale"]] <- nm
  for (vs in names(mods[[nm]])) cppars[[vs]] <- mods[[nm]][[vs]]
  write_json(cppars, gsub("template",sprintf("%s/%s",tardir,nm),.args[1]), pretty = TRUE, auto_unbox = TRUE)
})
