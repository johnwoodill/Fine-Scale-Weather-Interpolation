######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 11/23/2015
# Filename  : interpolation_mc.R
# Code      : Build fine scale data for tmax,tmin and ppt using multi-cores
#             (1) Build data frame for each PRISM and use spline interpolation to get base range
#             (2) Use relative anomaly to adjust base PRISM to NCDC daily
#
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################

###############################################################################################################################
#
# (1) Build data frame for each PRISM and use spline interpolation to get base range
#
###############################################################################################################################

library(dplyr)
library(parallel)
cl <- makeCluster(10)


# Load PRISM monthly data from prism_convert.R
i <- unique(list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/gridNumber/"))

# For subsetting missing files
miss <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/base/")
missing <- setdiff(i, miss)
i <- missing

# Load lat and long data for gridNumber verification
prism_lookup_unique <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/prism_lookup_unique.rds")

# Build base data for merge
base <- data.frame(date = seq(as.Date("1899-12-15"), as.Date("2013-1-15"), "days"))
base$year <- as.numeric(substr(base$date, 1, 4))
base$month <- as.numeric(substr(base$date, 6, 7))
base$day <- as.numeric(substr(base$date, 9, 10))

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(unique(i)), initial = 0)
stepi <- 0

comp <- function(x) { 
  #Load file to build
  df <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/gridNumber/",x))
  
  # Add day 15 for merge
  df$day <- as.numeric(15)
  
  # Add lat/long from prism lookup for verification
  df$lat <- prism_lookup_unique[prism_lookup_unique$gridNumber == substr(x, 1, nchar(basename(x))-4),2]
  df$long <- prism_lookup_unique[prism_lookup_unique$gridNumber == substr(x, 1, nchar(basename(x))-4),3]
  
  # Breakout by element
  df_tmin <- filter(df, element == "tmin")
  df_tmax <- filter(df, element == "tmax")
  
  # Merge data from empty data set with all dates, and breakout by element
  # Then fill in missing values with same in each column
  base_tmin <- left_join(base, df_tmin, by = c("year", "month", "day"))
  base_tmin[,5:12 ] <- lapply(base_tmin[,5:12], function(x) x[!is.na(x)][1])
  
  base_tmax <- left_join(base, df_tmax, by = c("year", "month", "day"))
  base_tmax[,5:12 ] <- lapply(base_tmax[,5:12], function(x) x[!is.na(x)][1])
  
  
  
  # Spline interpolation
  
  #tmin
  values_by_date <- splinefun(unique(base_tmin[base_tmin$day == 15, 1]), base_tmin[!is.na(base_tmin$mean),13 ])
  base_tmin$value <- values_by_date(seq.Date(base_tmin$date[1], tail(base_tmin$date,1), by = "day"))
  base_tmin$mean <- NULL
  
  #tmax
  values_by_date <- splinefun(unique(base_tmax[base_tmax$day == 15, 1]), base_tmax[!is.na(base_tmax$mean),13 ])
  base_tmax$value <- values_by_date(seq.Date(base_tmax$date[1], tail(base_tmax$date,1), by = "day"))
  base_tmax$mean <- NULL
  
  newbase <- bind_rows(base_tmin, base_tmax)
  newbase$value <- round(newbase$value, 4)
  
  saveRDS(newbase, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/base/",x))


}

	clusterExport(cl, c("prism_lookup_unique", "base"))
	clusterExport(cl, c("splinefun", "spline"))
	clusterCall(cl, function() library(dplyr))
	parLapply(cl, X = i, fun = comp)
	
	
###############################################################################################################################
#
# (2) Use relative anomaly to adjust base PRISM to NCDC daily
#
###############################################################################################################################

library(dplyr)
library(reshape2)
library(tidyr)
library(fields)


# Function to check for tmin >= tmax, fill with NA, and return
check <- function(y){
  y <- spread(y, element, value)
  names(y) <- tolower(names(y))
  y$tmax[y$tmin >= y$tmax] <- NA
  y$tmin[y$tmin >= y$tmax] <- NA
  y <- gather(y, key = element, tmax, tmin, value = value) #[names(y)]
  y <- y[order(y$date),]
  row.names(y) <- 1:length(y$id)
  return(y)
}

# Function to get weights
sweights <- function(m_coord, s_coord){
  d_mat <- rdist(m_coord, s_coord)
  w_mat <- 1 / d_mat ^ 2
  is_inf <- is.infinite(w_mat)
  has_infinite <- rowSums(is_inf) > 0
  w_mat[has_infinite, ] <- as.numeric(is_inf[has_infinite, ])
  keep_n <- function(x, n = 5) ifelse(rank(x) > length(x)-n, x, 0)
  w_mat <- t(apply(w_mat, 1, keep_n))
  w_mat <-  w_mat / rowSums(w_mat)
  return(w_mat)
}


ra <- function(row_loc, sweight, sstack){
  s_values <- sstack[row_loc:(row_loc+4),8]
  z <- is.na(s_values)
  v <- (sweight %*% ifelse(z, 0, s_values)) / (sweight %*% !z)
  return(v)
} 

# Load PRISM monthly data from prism_convert.R
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/base/")

# Load nearest PRISM lookup
prism_nearest <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/prism_nearest.rds")

# Load NCDC lookup for distance weighting
ncdc_lookup <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/ncdc_lookup_unique.rds")

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(unique(files)), initial = 0)
stepi <- 0

comp <- function(x){
  station <- as.data.frame(readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/base/", x)))
  station <- filter(station, element == "tmax" | element == "tmin")
  loc <- which(prism_nearest[,1] == station[1,5])
  s <- filter(ncdc_lookup, id %in% c(prism_nearest[loc,4:8]))
  m_coord <- station[1,9:10]
  s_coord <- data.frame(lat = s$lat, long = s$long)
  weight <- sweights(m_coord, s_coord)

  s1 <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/", prism_nearest[loc,4], ".rds"))
  s2 <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/", prism_nearest[loc,5], ".rds"))
  s3 <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/", prism_nearest[loc,6], ".rds"))
  s4 <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/", prism_nearest[loc,7], ".rds"))
  s5 <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/", prism_nearest[loc,8], ".rds"))
  
  s1$element <- as.character(unlist(s1$element))
  s2$element <- as.character(unlist(s2$element))
  s3$element <- as.character(unlist(s3$element))
  s4$element <- as.character(unlist(s4$element))
  s5$element <- as.character(unlist(s5$element))
  
  s1 <- filter(s1, element == "TMAX" | element == "TMIN")
  s2 <- filter(s2, element == "TMAX" | element == "TMIN")
  s3 <- filter(s3, element == "TMAX" | element == "TMIN")
  s4 <- filter(s4, element == "TMAX" | element == "TMIN")
  s5 <- filter(s5, element == "TMAX" | element == "TMIN")
  

  # Check to make sure tmin !>= TMAX
  s1 <- check(s1)
  s2 <- check(s2)
  s3 <- check(s3)
  s4 <- check(s4)
  s5 <- check(s5)
  
  s1 <- arrange(s1, date, element)
  s2 <- arrange(s2, date, element)
  s3 <- arrange(s3, date, element)
  s4 <- arrange(s4, date, element)
  s5 <- arrange(s5, date, element)
  
  station <- arrange(station, date, element)
  
  s1$r <- s1$value / station$value 
  s2$r <- s2$value / station$value 
  s3$r <- s3$value / station$value 
  s4$r <- s4$value / station$value 
  s5$r <- s5$value / station$value 
  
  sstack <- rbind(s1, s2, s3, s4, s5)
  sstack <- arrange(sstack, date, element)
  
  newval <- sapply(1:nrow(station), function (i) station[i,13] * ra(row_loc = (5*(i-1)+1), sweight = weight, sstack = sstack))
  newval <- round(newval, 4)
  
  station$values <- newval
  
  # If NA then use PRISM data
  station$values <- ifelse(is.na(station$values), station$value, station$values)

  # Keep only interpolated values
  station$value <- station$values
  station$values <- NULL
  
  # Spread new data
  station$element <- tolower(station$element)
  station <- spread(station, element, value)
  station <- arrange(station, date)
  
  # Double check for tmin >= TMAX because of PRISM data being inserted may be large than IDW data
  # If larger, use PRISM spline interpolated data
  prism <- as.data.frame(readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/base/", x)))
  prism <- spread(prism, element, value)
  prism <- arrange(prism, date)
  
  i1 <- !with(station, tmax > tmin)
  station[i1, c('tmax', 'tmin')] <- prism[i1, c('tmax', 'tmin')]
  
  chk <- which(station$tmin >= station$tmax)
  
  if(length(chk) > 0) print(paste0("ERROR:  ", x))
  
  # Save to base folder
  saveRDS(station, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/grids/", x))

}

library(parallel)
i <- unique(files)
cl <- makeCluster(16)
clusterExport(cl, c("prism_nearest", "ncdc_lookup"))
clusterExport(cl, c("check", "sweights", "ra"))
clusterCall(cl, function() library(dplyr))
clusterCall(cl, function() library(reshape2))
clusterCall(cl, function() library(tidyr))
clusterCall(cl, function() library(fields))
parLapply(cl, X = i, fun = comp)
