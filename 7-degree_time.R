######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 08/16/2016
# Filename  : degree_time.R
# Code      : Time in each degree during a day
#             (1) Get time in each degree
#             (2) rbind all fips together
#
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################

library(dplyr)


############################################################
#
# (1) Get time in each degree
#
############################################################

# C to F conversion
fartocel <- function(x) (x-32) * 5/9

days.in.range <- function( t0, t1 , tMin, tMax, noGrids )  {
    # Estimates time (in days) when temperature is between t0 and t1 
    # using sine curve interpolation.
    #
    # Args:
    #   t0: Time between t0
    #   t1: Time between t1
    #   tMin: vector of day minimum over range of interest
    #   tMax: vectors of day maximum over range of interest
    #   noGrids: number of grids in data from aFipsYear
    #
    # Returns:
    #   The sum of time in the interval is returned
  
    n   =  length(tMin)
    t0  =  rep(t0, n)
    t1  =  rep(t1, n)
    t0[t0 < tMin]   =  tMin[t0 < tMin]
    t1[t1 > tMax]  =  tMax[t1 > tMax]
    u  =  function(z, ind) (z[ind] - tMin[ind])/(tMax[ind] - tMin[ind])  
    outside  =  t0 > tMax | t1 < tMin
    inside  =  !outside
    time.at.range  =  ( 2/pi )*( asin(u(t1,inside)) - asin(u(t0,inside)) ) 
    return( ifelse(sum(time.at.range)/noGrids == "NaN", sum(time.at.range, na.rm = TRUE)/noGrids, sum(time.at.range)/noGrids))
}
 
aFipsYear  =  function(z){
    # This function calculates all 1-degree temperature intervals for 
    # a given row (fips-year combination)
    #
    # Note: that nested objects below must be defined in the outer environment.
    #
    # Args:
    #   w: weather data that includes a "fips" county ID, "gridNumber", "tMin" and "tMax".
    #      rows of w span all days, fips, years and grids being aggregated
    #   tempDat: pulls the particular fips/year of w being aggregated.
    #   Trows: expand.grid( fips.index, year.index ), rows span the aggregated data set
    #   T: a vector of integer temperatures.  I'm approximating the distribution with 
    #      the time in each degree in the index T
    #   noGrids: number of grids in data from aFipsYear
    #
    # Returns:
    #   1-degree temperature intervales defined in T
    ayear    = Trows$year[z]
    tempDat  = w[w$year==ayear, ]
    Tvect = c()
    for ( k in 1:length(T) ) Tvect[k] = days.in.range(
                t0   = T[k]-0.5, 
                t1   = T[k]+0.5, 
                tMin = tempDat$tmin, 
                tMax = tempDat$tmax,
                noGrids = length(unique(tempDat$gridNumber))
                )
    Tvect
}

### Begin for loop to cycle through each fips

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/")

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(unique(files)), initial = 0)
stepi <- 0

for (i in unique(files)){
  days <- data.frame()
  w <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/", i))
  Trows <- expand.grid(unique(w$fips), unique(w$year))
  names(Trows) <- c("fips", "year")
  T <- 0:45
  w$tmax <- fartocel(w$tmax)
  w$tmin <- fartocel(w$tmin)

  for (j in 1:length(Trows$fips)){
    fips <- as.data.frame(t(aFipsYear(j)))
    names(fips) <- c("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
                     "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34" ,"35", "36", "37", "38", "39", 
                     "40", "41", "42", "43", "44", "45")
    fips$fips <- Trows$fips[j]
    fips$year <- Trows$year[j]
    fips <- select(fips, fips, year, everything())
    days <- rbind(days, fips)
  }
  saveRDS(days, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreetime/fips/", i))
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}

############################################################
#
# (2) rbind all fips together
#
############################################################

library(data.table)

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreetime/fips/", full.names = TRUE)

full_degree_time <- rbindlist(lapply(files, readRDS))

# Save fips
library(readr)
library(foreign)
saveRDS(full_degree_time, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_time_1900-2013.rds")
write_csv(full_degree_time, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_time_1900-2013.csv")
write.dta(full_degree_time, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_time_1900-2013.dta")

saveRDS(full_degree_time, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreetime/fips/")
