#######################################################################################################
#------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 10/05/2015
# Filename  : prism_convert.R
# Code      : (1) Converts tmax, tmean, ppt, tmin *.bil to data frame and write as RData 
#             (send to MySql database option implemented)
#             (2) Merge and save each gridNumber for each tmax and tmin to directory
#------------------------------------------------------------------------------------------------------
#######################################################################################################

library(dplyr)
library(raster)
library(reshape2)
library(dplyr)
library(maps)
library(noncensus)
library(ggmap)
#library(RMySQL)

# C to F Conversion
celsiuscon <- function(x) {
  f = x * 1.8 + 32
  return(f)
}

# MM to Inches Conversion
mminches <- function(x){
  i = x * 0.039370
  return(i)
}

# Month to number
mo2Num <- function(x) match(tolower(x), tolower(month.abb))

# Get fips and gridNumber locations and merge
gridinfo <- read.csv("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/gridInfo.csv")
data(counties)
counties$fips <- as.integer(paste0(counties$state_fips, counties$county_fips))
counties <- counties[, c(9, 2, 1)]
fips_grid <- left_join(gridinfo, counties, by = "fips")


###############################################################################################################################
#
#       (1) Converts tmax, tmean, ppt, tmin *.bil to data frame and write as RData 
#
###############################################################################################################################

### Precipitation (ppt) ###

setwd("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/ppt/bil/")   

years <- 1899:2014
df <- data.frame()

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(years), initial = 0)
stepi <- 0

for (i in years) {
  filenames <- list.files(pattern=paste(".*_", i, ".*\\.bil$", sep = ""))
  s <- stack(filenames)
  y <- as.data.frame(s, na.rm = TRUE)
  y$long <- rasterToPoints(s)[,1]
  y$lat <- rasterToPoints(s)[,2]
  y$year <- i
  colnames(y) <- c("jan", "feb","mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec", "long", "lat", "year")
  z <- cbind(gridNumber = as.integer(rownames(y)), y)
  df_temp <- inner_join(fips_grid, z, by = "gridNumber")
  df <- bind_rows(df, df_temp)
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
  }

df[6:17] <- as.data.frame(lapply(df[6:17], mminches))

# Save RDS
saveRDS(df, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/ppt/ppt_1899-2014.rds")
df_ppt <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/ppt/ppt_1899-2014.rds")


##################################
### Max Temperature (tmax)     ###
##################################


# Month to number
mo2Num <- function(x) match(tolower(x), tolower(month.abb))

setwd("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmax/bil/")    # Set to directory with *.hdr and *.bil

years <- 1899:2014
df <- data.frame()

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(years), initial = 0)
stepi <- 0

for (i in years) {
  filenames <- list.files(pattern=paste(".*_", i, ".*\\.bil$", sep = ""))
  s <- stack(filenames)
  y <- as.data.frame(s, na.rm = TRUE)
  y$long <- rasterToPoints(s)[,1]
  y$lat <- rasterToPoints(s)[,2]
  y$year <- i
  colnames(y) <- c("jan", "feb","mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec", "long", "lat", "year")
  z <- cbind(gridNumber = as.integer(rownames(y)), y)
  df_temp <- inner_join(fips_grid, z, by = "gridNumber")
  df <- bind_rows(df, df_temp)
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}

# Convert C to F
df[6:17] <- as.data.frame(lapply(df[6:17], celsiuscon))

# Save RDS
system.time(saveRDS(df, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmax/tmax_1899-2015.rds"))
df_tmax <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmax/tmax_1899-2015.rds")



##################################
### Minimum Temperature (tmin) ###
##################################


rm(list=ls(all=TRUE))


# Month to number
mo2Num <- function(x) match(tolower(x), tolower(month.abb))

setwd("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmin/bil/")    # Set to directory with *.hdr and *.bil
years <- 1899:2014
db_df <- data.frame()

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(years), initial = 0)
stepi <- 0

for (i in years) {
  filenames <- list.files(pattern=paste(".*_", i, ".*\\.bil$", sep = ""))
  s <- stack(filenames)
  y <- as.data.frame(s, na.rm = TRUE)
  y$long <- rasterToPoints(s)[,1]
  y$lat <- rasterToPoints(s)[,2]
  y$year <- i
  colnames(y) <- c("jan", "feb","mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec", "long", "lat", "year")
  z <- cbind(gridNumber = as.integer(rownames(y)), y)
  df_temp <- inner_join(fips_grid, z, by = "gridNumber")
  df <- bind_rows(df, df_temp)
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}

# Convert C to F
df[6:17] <- as.data.frame(lapply(df[6:17], celsiuscon))

# Save RDS
saveRDS(df, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmin/tmin_1899-2015.rds")
df_tmin <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmin/tmin_1899-2015.rds")


###############################################################################################################################
#
#       (2) Merge and save each gridNumber for each ppt, tmax, and tmin to directory
#
###############################################################################################################################

library(dplyr)
library(reshape2)

# Check on map where station locations are
map <- get_map(location = "united states", zoom = 9)
mapPoints <- ggmap(map) + geom_point(data = test, aes(x=long, y = lat)) + ggtitle("PRISM Stations")
plot(mapPoints)

# Month to number
mo2Num <- function(x) match(tolower(x), tolower(month.abb))


df_tmin <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmin/tmin_1899-2014.rds")
df_tmax <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmax/tmax_1899-2014.rds")
df_ppt <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/ppt/ppt_1899-2014.rds")
gridNumber <- unique(df_tmin$gridNumber)

# Subset out gridNumbers already complete
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/gridNumber/")
files <- substr(basename(files), 1, nchar(basename(files))-4)
gridNumber <- setdiff(gridNumber, files)

# Creat progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(gridNumber), initial = 0)
stepi <- 0


for (i in unique(gridNumber)) {
  # Subset data for each gridNumber by tmax and tmin
  output1 <- filter(df_tmin, gridNumber == i)
  output1$element <- "tmin"
  output2 <- filter(df_tmax, gridNumber == i)
  output2$element <- "tmax"
  output3 <- filter(df_ppt, gridNumber == i)
  output3$element <- "ppt" 
  output <- bind_rows(output1, output2, output3)
  
  # Melt data, clean, and write out
  output <- melt(output, id = c("fips", "county_name", "state", "gridNumber", "cropArea", "lat", "long", "year", "element"))
  output$variable <- mo2Num(output$variable)
  output$value <- round(output$value, 3)
  colnames(output) <- c("fips", "county", "state", "gridNumber", "cropArea", "lat", "long", "year", "element", "month", "mean")
  output <- select(output, gridNumber, fips, county, state, lat, long, cropArea, year, month, element, mean)  
  
  filename <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/gridNumber/", i, ".rds")
  saveRDS(output, filename)
  
  # Progress bar
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}

length(list.files("/run/media/john/1TB/Projects/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/Data/PRISM/gridNumber/"))
