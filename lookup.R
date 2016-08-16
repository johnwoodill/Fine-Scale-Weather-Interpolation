######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 08/16/2016
# Filename  : lookup.R
# Code      : Build look up tables for NCDC data and PRISM data to find nearest NCDC stations to PRISM grid
#             (1) NCDC look up table
#             (2) PRISM look up table
#             (3) Find closests 5 NCDC stations for each PRISM grid
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################

### Library

library(dplyr)
library(reshape2)
library(sp)
library(ggmap)

### Functions

# Month to number
mo2Num <- function(x) match(tolower(x), tolower(month.abb))





###############################################################################################################################
#
# (1) NCDC look up table
#
###############################################################################################################################

# Get all NCDC stations 
sid <- read.csv("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC_sid.csv", stringsAsFactors = FALSE)

ncdc_lookup_unique <- distinct(sid, id)
ncdc_lookup_unique <- select(ncdc_lookup_unique, id, lat, long, state)

saveRDS(ncdc_lookup_unique, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/ncdc_lookup_unique.rds")

###############################################################################################################################
#
# (2) PRISM look up table
#
###############################################################################################################################

### TMIN

df_tmin <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/tmin/tmin_1899-2014.rds")

output_tmin <- melt(df_tmin, id = c("fips", "county_name", "state", "gridNumber", "cropArea", "lat", "long", "year"))
output_tmin <- select(output_tmin, gridNumber, lat, long)
colnames(output_tmin) <- c("gridNumber", "lat", "long")


output_sub <- output_tmin[!duplicated(output_tmin$gridNumber),]

saveRDS(output_sub, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/prism_lookup_unique.rds")




###############################################################################################################################
#
# (3) Find closests 5 NCDC stations for each PRISM grid
#
###############################################################################################################################


# Load previous lookup tables
prism_lookup_unique <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/prism_lookup_unique.rds")
ncdc_lookup_unique <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/ncdc_lookup_unique.rds")


# Set sp
prism_nearest <- prism_lookup_unique
ncdc_dummy <- ncdc_lookup_unique
prism_nearest[c("s1", "s2", "s3", "s4", "s5")] <- NA



coordinates(prism_lookup_unique) = c('long', 'lat')
coordinates(ncdc_lookup_unique) = c('long', 'lat')
proj4string(prism_lookup_unique) = "+proj=longlat +datum=WGS84"
proj4string(ncdc_lookup_unique) = "+proj=longlat +datum=WGS84"

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(prism_lookup_unique$gridNumber), initial = 0)
stepi <- 0

for (i in 1:length(prism_nearest$gridNumber)){
  set <- order(apply(spDists(prism_lookup_unique[i,],ncdc_lookup_unique),2,min))[1:5]
  prism_nearest[i, 4] <- ncdc_dummy$id[set[1]]
  prism_nearest[i, 5] <- ncdc_dummy$id[set[2]]
  prism_nearest[i, 6] <- ncdc_dummy$id[set[3]]
  prism_nearest[i, 7] <- ncdc_dummy$id[set[4]]
  prism_nearest[i, 8] <- ncdc_dummy$id[set[5]]
  
  # Progress bar
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}

saveRDS(prism_nearest, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/prism_nearest.rds")


