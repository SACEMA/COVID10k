suppressPackageStartupMessages({
  require(remotes)
  require(data.table)
})

.args <- if (interactive()) c("latest_who.rds") else commandArgs(trailingOnly = TRUE)

remotes::install_github("eebrown/data2019nCoV", upgrade = "always")
require(data2019nCoV)

ref <- data.table(WHO_SR)

# only work to do if updates
if (!file.exists(.args[1]) || (readRDS(.args[1])[.N, date] < ref[.N, Date])) {
  ctys.cases <- grep("deaths", colnames(ref), invert = T, value = TRUE)
  ctys.deaths <- grep("deaths", colnames(ref), value = TRUE)
  #' WARNING: assumes that Africa region remains a block
  #'  that starts after Region.EasternMediterranean
  
  afr.cases <- c(
    ctys.cases[
      (which(ctys.cases == "Region.EasternMediterranean")+1) :
        (which(ctys.cases == "Region.African")-1)
      ],
    c("Sudan","Somalia","Djibouti","Tunisia","Morocco","Egypt")
  )
  
  SR <- melt(
    ref[,.SD,.SDcols = intersect(colnames(ref), c(afr.cases)), by=.(SituationReport, Date)],
    id.vars = c('SituationReport','Date'), variable.factor = F
  )
  SR[, country := gsub("\\..+$","",variable) ]
  SR[, measure := gsub("^.+\\.(.+)$","\\1", variable) ]
  SR[measure == variable, measure := "cases" ]
  saveRDS(SR[,.(value),keyby=.(country,measure,date=Date)], tail(.args, 1))
}

