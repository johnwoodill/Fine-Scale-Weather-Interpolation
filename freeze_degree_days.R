######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 12/27/2015
# Filename  : freeze_degree_days.R
# Code      : Days in each degree during a day
#             (1) Get negative days in each degree
#
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################

library(dplyr)

# C to F conversion
fartocel <- function(x) (x-32) * 5/9

bound_list <- 0

comp <- function(x){
  df <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/", x))
   
  # Turn to celcius
  df$tmax <- fartocel(df$tmax)
  df$tmin <- fartocel(df$tmin)
  
  # Generate average temp
  df$tavg <- (df$tmax + df$tmin)/2
  
  # Generate new columns for degree days from bound_list
  nc <- ncol(df)
  
  for (i in 1:length(bound_list)){
    col <- paste0("ndday", abs(bound_list[i]), "C")
    cadd <- i + nc
    b <- bound_list[i]
    df[,cadd] <- 0
    df[,cadd] <- ifelse(b >= df$tmax, abs(df$tavg - b), df[,cadd])
    temp <- acos((2*b - df$tmax - df$tmin)/(df$tmax - df$tmin))
    df[,cadd] <- ifelse(df$tmin < b & b < df$tmax, df$tmax - df$tavg - ((df$tavg - b)*temp + (df$tmax - df$tmin)*sin(temp)/2)/pi, df[,cadd])
    df[,cadd] <- round(df[,cadd], 5)
    colnames(df)[cadd] <- col
}

# Sum over each grid days
df <- df %>% 
  group_by(gridNumber, fips, year, month) %>% 
  summarize(ndday0C = sum(ndday0C),
            tmin = mean(tmin),
            tmax = mean(tmax),
            tavg = mean(tavg))
    
# Average over each fips
df <- df %>% 
  group_by(fips, year, month) %>% 
  summarize(ndday0C = mean(ndday0C),
            tmin = mean(tmin),
            tmax = mean(tmax),
            tavg = mean(tavg))
    df <- filter(df, year >= 1900 & year <= 2012)

    saveRDS(df, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/ndegreedays/fips/", x))
}

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/")
infiles <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/ndegreedays/fips/")
 
i <- files
i <- setdiff(files, infiles)

library(parallel)
cl <- makeCluster(10)
clusterExport(cl, c("fartocel"))
clusterExport(cl, c("bound_list"))
clusterCall(cl, function() library(dplyr))
parLapply(cl, X = i, fun = comp)
stopCluster(cl)

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/ndegreedays/fips/", full.names = TRUE)

# rbind all files
library(data.table)
full_ndegree_days <- rbindlist(lapply(files, readRDS))
full_ndegree_days <- select(full_ndegree_days, fips, year, month, ndday0C)

# Merge with degree days
mergedat <- readRDS("Data/fips_degree_days_1900-2013.rds")
full_dat <- left_join(mergedat, full_ndegree_days, by = c("fips", "year", "month"))

# Save fips
library(readr)
library(foreign)
saveRDS(full_dat, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.rds")
write.csv(full_dat, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.csv")
write.dta(full_dat, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.dta")

# For error checking .rds files 
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/ndegreedays/fips/", full.names = TRUE) 
test <- as.data.frame(files)
files <- files[1890:3105]

for (i in files){
  df <- readRDS(i)
  print(i)
}


