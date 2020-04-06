# map the summary results - time to 1K and time to 10K
suppressPackageStartupMessages({
  require(sp)
  require(rgdal)
  require(maps) 
  require(mapdata)
  require(RColorBrewer)
  require(ptinpoly)
  require(tmap)
  require(sf)
  require(ggplot2)
  require(ggrepel)
})

.args <- if (interactive()) c(
  "Shapefiles/Detailed/detailed_2013.shp",
  "~/Dropbox/COVIDSA/outputs/figs/estimate-all.csv",
  "~/Dropbox/COVIDSA/outputs/figs/map_inset.png"
) else commandArgs(trailingOnly = TRUE)

admn0 <- readOGR(.args[1], "detailed_2013")
sims <- read.csv(.args[2])

#' @examples to get the countries in Africa but not AFRO...
# table(as.character(admn0$CNTRY_TERR[admn0$WHO_REGION=="EMRO"]))
admn0afr <- subset(admn0,
  WHO_REGION=="AFRO" |
  CNTRY_TERR %in% c("Djibouti", "Egypt", "Libya", "Morocco", "Somalia", "Sudan", "Tunisia")
)

# to reduce the size we have 2 options
# 1) restrict the shapes
# restrict the axes




#' @examples check regions
#' tm_shape(admn0afr) +
#'   tm_polygons("WHO_REGION") + 
#'   tm_layout(
#'     legend.position=c("left","bottom"),
#'     legend.text.size=2,
#'     legend.title.size=2.2
#'   )

# load in timing estimates

# not all the names are going to match - for now do these ones by hand 
admn0afr$k1 <- admn0afr$k10 <- 0
admn0afr$CNTRY_TERRns <- gsub(" ","",admn0afr$CNTRY_TERR)
  
sims1 <- subset(sims,value==1000)    # 1k cases
sims1$ref <- c(1:dim(sims1)[1])

dating <- function(x) as.Date(as.character(x))

# 1k first
oo <- match(as.character(admn0afr$CNTRY_TERRns),sims1$country)
admn0afr$CNTRY_TERR[is.na(oo)]
admn0afr$k1 <- dating(sims1$med[oo])
admn0afr$k1alpha <- dating(sims1$hi[oo])-dating(sims1$lo[oo])

# present but spelt differently...
# Côte d'Ivoire
admn0afr$k1[21] <- dating(sims1$med[10])
admn0afr$k1alpha[21] <- dating(sims1$hi[10])-dating(sims1$lo[10])

# Réunion
admn0afr$k1[37] <- dating(sims1$med[33])
admn0afr$k1alpha[37] <- dating(sims1$hi[33])-dating(sims1$lo[33])


# Swaziland
admn0afr$k1[51] <- dating(sims1$med[16])
admn0afr$k1alpha[51] <- dating(sims1$hi[16])-dating(sims1$lo[16])

# make day from 01-01-2020
admn0afr$k1jan <- as.numeric(difftime(admn0afr$k1,"2020-01-01"))
cbind(as.character(admn0afr$CNTRY_TERR),as.character(admn0afr$k1),as.numeric(admn0afr$k1jan))

# update labels
admn0afr$labels <- admn0afr$CNTRY_TERR
levels(admn0afr$labels) <- c(levels(admn0afr$labels)," ","CAR","DR Congo","Tanzania")
admn0afr$labels[admn0afr$CNTRY_TERR=="Cabo Verde" | admn0afr$CNTRY_TERR=="Comoros" | admn0afr$CNTRY_TERR=="Mayotte" |                   
                admn0afr$CNTRY_TERR=="Mauritius" | admn0afr$CNTRY_TERR=="Réunion" | 
                  admn0afr$CNTRY_TERR=="Seychelles" | 
                  admn0afr$CNTRY_TERR=="Saint Helena" | admn0afr$CNTRY_TERR=="Sao Tome and Principe"] <- c(" ")
admn0afr$labels[admn0afr$CNTRY_TERR=="Central African Republic"] <- "CAR"
admn0afr$labels[admn0afr$CNTRY_TERR=="Democratic Republic of the Congo"] <- "DR Congo"
admn0afr$labels[admn0afr$CNTRY_TERR=="United Republic of Tanzania"] <- "Tanzania"

# plot expected date
# we want to specify the breaks
#vals <- 
#brks <- seq(as.numeric(difftime(as.Date(c("23/03/2020"),"%d/%m/%Y"),"2020-01-01")),82+(7*8),7) # 7 days
#brks <- seq(as.numeric(difftime(as.Date(c("23/03/2020"),"%d/%m/%Y"),"2020-01-01")),82+(7*8),3)  # 3 days (for both)

brks <- c(1, seq(90, by=3, length.out = 8), 1000)
# brks <- c(80, seq(
#   as.numeric(difftime(as.Date(c("01/04/2020"),"%d/%m/%Y"),"2020-01-01")),
#   as.numeric(difftime(as.Date(c("01/04/2020"),"%d/%m/%Y"),"2020-01-01")) + 18,
#   3
# ), 200) # 3 days
l1 <- as.character(format(as.Date(brks,origin="2020-01-01"),"%b-%d"))
labels <- paste0(l1[1:(length(l1)-1)]," to ",l1[2:(length(l1))])
  

# 1k alone
wd <- 2.5
png(
  tail(.args, 1),
  height=wd*5/6, width=wd,
  units = "in", res = 600,
  bg = "transparent"
)
tm_shape(admn0afr) + tm_fill(
  title="Timing of first \n1,000 Covid-19 cases",
  textNA = "No cases reported as of 23 March 2020",
  col="k1jan",palette="-YlOrRd",breaks=brks,labels=labels,
  legend.show = F
) + 
  tm_text("labels",size=0.2) +
  tm_layout(frame = FALSE, bg.color = "transparent")
dev.off()

# 1k alone with alpha
# jpeg("~/Documents/GitHub/COVID10k/Plots/1k_3day_alpha_date.jpeg",height=1000,width=2000)
# m1 <- tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
#                              textNA = "No cases reported as of 23 March 2020",
#                              col="k1jan",palette="-YlOrRd",breaks=brks,labels=labels) + 
#   tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
#             legend.title.size=2.2)
# ma <- tm_shape(admn0afr) + tm_fill(title="Uncertainty in estimate (days)",
#                                    textNA = "No cases reported as of 23 March 2020",
#                                    col="k1alpha",palette="BuPu") + 
#   tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
#             legend.title.size=2.2)
# tmap_arrange(m1, ma)
# dev.off()
# 
# # 10k alone
# jpeg("~/Documents/GitHub/COVID10k/Plots/10k_date.jpeg",height=1000,width=1200)
# tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
#                              textNA = "No cases reported",
#                              col="k1jan",palette="RdYlBu",breaks=brks,labels=labels) + 
#   tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
#             legend.title.size=2.2)
# dev.off()
# 
# # joint figure
# jpeg("~/Documents/GitHub/COVID10k/Plots/timeto_both_3days_02Apr20.jpeg",height=1000,width=2000)
# m1 <- tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
#                              textNA = "No cases reported as of 23 March 2020",
#                              col="k1jan",palette="RdYlBu",breaks=brks,labels=labels) + 
#   tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
#             legend.title.size=2.2)
# m10 <- tm_shape(admn0afr) + tm_fill(title="Timing of first \n10,000 Covid-19 cases",
#                                    textNA = "no cases reported as of 23 March 2020",
#                                    col="k10jan",palette="RdYlBu",breaks=brks,labels=labels) + 
#   tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,   # ok this is being recognised
#             legend.title.size=2.2)
# tmap_arrange(m1, m10)
# dev.off()
# # end