# map the summary results - time to 1K and time to 10K
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

dir <- "~/Documents/GitHub/COVID10k/Shapefiles/Detailed/detailed_2013.shp" #"~/Dropbox/Covid-19-season/Rcode/Admin1(2011)/admin1.shp"
name <- "detailed_2013"
admn0 <- readOGR(dir,name)
shpdat0 <- data.frame(admn0@data)
dim(shpdat0)  # 224 polygons
# output

# to reduce the size we have 2 options
# 1) restrict the shapes
# restrict the axes

#admn0afr <- admn0[admn0$WHO_REGION=="AFRO" | admn0$WHO_REGION=="EMRO",]
admn0afr <- admn0[admn0$WHO_REGION=="AFRO" | 
                    (admn0$CNTRY_TERR=="Djibouti" | admn0$CNTRY_TERR=="Egypt" | admn0$CNTRY_TERR=="Libya"  | admn0$CNTRY_TERR=="Morocco" | admn0$CNTRY_TERR=="Somalia" | admn0$CNTRY_TERR=="Sudan" | admn0$CNTRY_TERR=="Tunisia"),]

table(as.character(admn0$CNTRY_TERR[admn0$WHO_REGION=="EMRO"]))

# improve how the legend is plotted
jpeg("~/Documents/GitHub/COVID10k/Plots/test01.jpeg",height=1000,width=1200)
tm_shape(admn0afr) + tm_polygons("WHO_REGION") + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=2,  # ok this is being recognised
            #earth.boundary = c(-100, -60, 180, 20),
            legend.title.size=2.2)
dev.off()

# load in timing estimates
sims <- read.csv("~/Dropbox/COVIDSA/outputs/estimates-all.csv")
# not all the names are going to match - for now do these ones by hand 
admn0afr$k1 <- admn0afr$k10 <- 0
admn0afr$CNTRY_TERRns <- gsub(" ","",admn0afr$CNTRY_TERR)
  
sims1 <- subset(sims,value==1000)    # 1k cases
sims1$ref <- c(1:dim(sims1)[1])
sims10 <- subset(sims,value==10000)  # 10k cases
sims10$ref <- c(1:dim(sims10)[1])

# 1k first
oo <- match(as.character(admn0afr$CNTRY_TERRns),sims1$country)
admn0afr$CNTRY_TERR[is.na(oo)]
admn0afr$k1 <- as.Date(sims1$date[oo],format="%Y-%m-%d")+sims1$med[oo]
admn0afr$k1alpha <- sims1$hi[oo]+sims1$lo[oo]

# 10k also 
aa <- match(as.character(admn0afr$CNTRY_TERRns),sims10$country)
admn0afr$CNTRY_TERR[is.na(aa)]
admn0afr$k10 <- as.Date(sims10$date[aa],format="%Y-%m-%d")+sims10$med[aa]
admn0afr$k10alpha <- sims10$hi[aa]+sims10$lo[aa]

# present but spelt differently...
# Côte d'Ivoire
admn0afr$k1[21] <- as.Date(sims1$date[10],format="%Y-%m-%d")+sims1$med[10]
admn0afr$k10[21] <- as.Date(sims10$date[10],format="%Y-%m-%d")+sims10$med[10]
admn0afr$k1alpha[21] <- sims1$hi[21]+sims1$lo[21]
admn0afr$k10alpha[21] <- sims10$hi[21]+sims10$lo[21]

# Réunion
admn0afr$k1[37] <- as.Date(sims1$date[33],format="%Y-%m-%d")+sims1$med[33]
admn0afr$k10[37] <- as.Date(sims10$date[33],format="%Y-%m-%d")+sims10$med[33]
admn0afr$k1alpha[37] <- sims1$hi[33]+sims1$lo[33]
admn0afr$k10alpha[37] <- sims10$hi[33]+sims10$lo[33]

# Swaziland
admn0afr$k1[51] <- as.Date(sims1$date[16],format="%Y-%m-%d")+sims1$med[16]
admn0afr$k10[51] <- as.Date(sims10$date[16],format="%Y-%m-%d")+sims10$med[16]
admn0afr$k1alpha[51] <- sims1$hi[16]+sims1$lo[16]
admn0afr$k10alpha[51] <- sims10$hi[16]+sims10$lo[16]

# make day from 01-01-2020
admn0afr$k1jan <- as.numeric(difftime(admn0afr$k1,"2020-01-01"))
admn0afr$k10jan <- as.numeric(difftime(admn0afr$k10,"2020-01-01"))
cbind(as.character(admn0afr$CNTRY_TERR),as.character(admn0afr$k1),as.numeric(admn0afr$k1jan),as.numeric(admn0afr$k10jan))

# plot expected date
# we want to specify the breaks
#vals <- 
#brks <- seq(as.numeric(difftime(as.Date(c("23/03/2020"),"%d/%m/%Y"),"2020-01-01")),82+(7*8),7) # 7 days
#brks <- seq(as.numeric(difftime(as.Date(c("23/03/2020"),"%d/%m/%Y"),"2020-01-01")),82+(7*8),3)  # 3 days (for both)
brks <- seq(as.numeric(difftime(as.Date(c("23/03/2020"),"%d/%m/%Y"),"2020-01-01")),82+(7*5),3) # 3 days
l1 <- as.character(format(as.Date(brks,origin="2020-01-01"),"%b-%d"))
labels <- paste0(l1[1:(length(l1)-1)]," to ",l1[2:(length(l1))])
  
# 1k alone
jpeg("~/Documents/GitHub/COVID10k/Plots/1k_3day_date.jpeg",height=1000,width=1200)
tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
                             textNA = "No cases reported",
                             col="k1jan",palette="RdYlBu",breaks=brks,labels=labels) + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
            legend.title.size=2.2)
dev.off()

# 1k alone with alpha
jpeg("~/Documents/GitHub/COVID10k/Plots/1k_3day_alpha_date.jpeg",height=1000,width=2000)
m1 <- tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
                             textNA = "No cases reported as of 23 March 2020",
                             col="k1jan",palette="-YlOrRd",breaks=brks,labels=labels) + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
            legend.title.size=2.2)
ma <- tm_shape(admn0afr) + tm_fill(title="Uncertainty in estimate (days)",
                                   textNA = "No cases reported as of 23 March 2020",
                                   col="k1alpha",palette="BuPu") + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
            legend.title.size=2.2)
tmap_arrange(m1, ma)
dev.off()

# 10k alone
jpeg("~/Documents/GitHub/COVID10k/Plots/10k_date.jpeg",height=1000,width=1200)
tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
                             textNA = "No cases reported",
                             col="k1jan",palette="RdYlBu",breaks=brks,labels=labels) + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
            legend.title.size=2.2)
dev.off()

# joint figure
jpeg("~/Documents/GitHub/COVID10k/Plots/timeto_both_3days_02Apr20.jpeg",height=1000,width=2000)
m1 <- tm_shape(admn0afr) + tm_fill(title="Timing of first \n1,000 Covid-19 cases",
                             textNA = "No cases reported as of 23 March 2020",
                             col="k1jan",palette="RdYlBu",breaks=brks,labels=labels) + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,  # ok this is being recognised
            legend.title.size=2.2)
m10 <- tm_shape(admn0afr) + tm_fill(title="Timing of first \n10,000 Covid-19 cases",
                                   textNA = "no cases reported as of 23 March 2020",
                                   col="k10jan",palette="RdYlBu",breaks=brks,labels=labels) + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=1.8,   # ok this is being recognised
            legend.title.size=2.2)
tmap_arrange(m1, m10)
dev.off()
# end