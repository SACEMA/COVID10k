require(tmap)

dir <- "~/Dropbox/Covid-19-season/Shapefiles/Generalised/general_2013.shp" #"~/Dropbox/Covid-19-season/Rcode/Admin1(2011)/admin1.shp"
name <- "general_2013"
admn0 <- readOGR(dir,name)
shpdat0 <- data.frame(admn0@data)
dim(shpdat0)  # 224 polygons
# output
# improve how the legend is plotted
jpeg("test01.jpeg",height=1000,width=2000)
tm_shape(admn0) + tm_polygons("WHO_REGION") + 
  tm_layout(legend.position=c("left","bottom"),legend.text.size=2,  # ok this is being recognised
            legend.title.size=2.2)
dev.off()