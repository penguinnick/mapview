#-- This script is a demonstration of how to use mapview to interact with your data. 
#-- Details about mapview and source code can be found on github: https://r-spatial.github.io/mapview/ 

#-- install mapview and color brewer
# install.packages("mapview")
# install.packages("RColorBrewer")

#-- may or may not need leaflet
# install.packages("leaflet")

#-- load packages
library(mapview)
library(RColorBrewer)
library(raster)
library(rgeos)

#-- set path to folder location
myDir <- "C:\\Users\\ntriozzi\\Box Sync\\2019_Spring\\WFS585\\mapview\\mapview"

#-- set working directory
setwd(myDir)

#-- read in raster layer
suit <- raster("suitability_clip.tif")

plot(suit)


#-- pretty neat, huh? Let's add some data to the map

#-- The suitability layer is projected to ETRS 89 / ETRS-LAEA (EPSG 3035). When called in mapview, the package projects the layer to web mercator (EPSG 3857). we can keep using our preferred CRS, but be careful because some transformations across projections will introduce spatial inaccuracy. You can set the resampling method used by mapview using the method option (see vignette)
crs <- proj4string(suit)


#-- read in point data
forts <- read.csv("hillforts.csv")

#-- create a SpatialPointsDataFrame for hillforts
coords<-data.frame(x = forts$utmE, y = forts$utmN)
f <- SpatialPointsDataFrame(coords= coords, data = forts, proj4string = CRS(crs))

plot(f, add=TRUE, pch=20)


#-- let's have our first look at mapview
m1 <- mapview(suit)
m1

#-- add the hillforts with a + sign
m1 + f

#-- Whoops! we have points outside the extent of the suitability layer. Let's keep only those that overlap the raster. 
#-- create bounding box polygon from extent of suitability layer
e <- extent(suit)
cp <- as(extent(e[1], e[2], e[3], e[4]), "SpatialPolygons")
proj4string(cp) <- crs

#-- keep only forts within extent of suitability layer
newf <- f[!is.na(over(f, cp)),]

#-- let's create a new map object with the subsetted points
m2 <- m1 + newf
m2

#-- Cool! Forts seem to be on the yellow. But what does yellow mean? Let's add a legend for the raster.
m2 <- mapview(suit, legend=TRUE) + newf
m2

#-- Let's see how they are distributed wrt age. Let's choose a nice color scheme using Cynthia Brewer's Color palettes, chosing the best palettes for qualitative data by setting "qual" under the"type" option and setting the colorblindFriendly option to TRUE (make your science accessible!)
#-- show color options. (a user-friendly version is found at http://colorbrewer2.org/#type=sequential&scheme=BuGn&n=3).
display.brewer.all(n=NULL, type="qual", select=NULL, exact.n=TRUE, colorblindFriendly=TRUE) 

#-- how many different colors do we need?
length(unique(f$date))

#-- I rather like Dark2. Let's try it with 4 colors 
myPal <- colorRampPalette(brewer.pal(4, "Dark2"))

#-- Much like ggplot2, mapview commands can be set as variables and combined in single commands. This really helps keep your code tidy. Let's use the label option to specify what the pop-up reads when we hover over a point with the mouse. More functionality here: https://environmentalinformatics-marburg.github.io/mapview/advanced/advanced.html#cex 
m3 <- mapview(suit, legend=T) + mapview(newf, zcol="date",  color=myPal, legend=TRUE, label=newf$Site)
m3

#-- add additional layers, like a buffer
buff <- gBuffer(newf, width=1000, byid=TRUE)

#-- make a new map with the buffers. Use alpha.regions=0 to drop polygon fill, lwd=3 to thicken the circle lines. Note how site labels are obscured because the buffers sit on top of our site points.
m4 <- mapview(buff, alpha.regions=0.3, lwd=3)
m <- m3 + m4  
m

#-- ready for something REALLY cool?
dem <- raster("dem_clip.tif")
myRasPal <- colorRampPalette(brewer.pal(9, "Greens"))
m5 <- mapview(dem, legend=TRUE, col.regions=myRasPal(100), at=seq(-4, 715, 10))
m6 <- mapview(newf, zcol="date",  color=myPal, legend=TRUE, label=newf$Site)
sat_map <- mapview(newf, zcol="date",  color=myPal, legend=TRUE, label=newf$Site, map.types="Esri.WorldImagery" )
topo_map <- mapview(newf, zcol="date",  color=myPal, legend=TRUE, label=newf$Site, map.types="OpenTopoMap")
dem_map <- m5 + m6
suit_map <- m
lv1 <- latticeview(suit_map, dem_map, sat_map, topo_map, sync="all")
lv1 # Wow!!
