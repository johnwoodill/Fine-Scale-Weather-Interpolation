######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 12/27/2015
# Filename  : degree_days.R
# Code      : Days in each degree during a day
#             (1) Get days in each degree
#
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################

library(dplyr)

# C to F conversion
fartocel <- function(x) (x-32) * 5/9

bound_list <- c(0:35)

comp <- function(x){
  df <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/", x))
   
  # Turn to celcius
  df$tmax <- fartocel(df$tmax)
  df$tmin <- fartocel(df$tmin)
  
  # Generate average temp
  df$tavg <- (df$tmax + df$tmin)/2
  
  # Generate new columns for degree days from bould_list
  nc <- ncol(df)
  
  for (i in 1:length(bound_list)){
    col <- paste0("dday", bound_list[i], "C")
    cadd <- i + nc
    b <- bound_list[i]
    df[,cadd] <- 0
    df[,cadd] <-ifelse(b <= df$tmin, df$tavg - b, 0)
    temp <- acos((2*b - df$tmax - df$tmin)/(df$tmax - df$tmin))
    df[,cadd] <- ifelse(df$tmin < b & b < df$tmax, ((df$tavg - b)*temp + (df$tmax - df$tmin)*sin(temp)/2)/pi, df[,cadd])
    df[,cadd] <- round(df[,cadd], 5)
    colnames(df)[cadd] <- col
}

# Sum over each grid days
df <- df %>% 
  group_by(gridNumber, fips, year, month) %>% 
  summarize(dday0C = sum(dday0C),
            dday1C = sum(dday1C),
            dday2C = sum(dday2C),
            dday3C = sum(dday3C),
            dday4C = sum(dday4C),
            dday5C = sum(dday5C),
            dday6C = sum(dday6C),
            dday7C = sum(dday7C),
            dday8C = sum(dday8C),
            dday9C = sum(dday9C),
            dday10C = sum(dday10C),
            dday11C = sum(dday11C),
            dday12C = sum(dday12C),
            dday13C = sum(dday13C),
            dday14C = sum(dday14C),
            dday15C = sum(dday15C),
            dday16C = sum(dday16C),
            dday17C = sum(dday17C),
            dday18C = sum(dday18C),
            dday19C = sum(dday19C),
            dday20C = sum(dday20C),
            dday21C = sum(dday21C),
            dday22C = sum(dday22C),
            dday23C = sum(dday23C),
            dday24C = sum(dday24C),
            dday25C = sum(dday25C),
            dday26C = sum(dday26C),
            dday27C = sum(dday27C),
            dday28C = sum(dday28C),
            dday29C = sum(dday29C),
            dday30C = sum(dday30C),
            dday31C = sum(dday31C),
            dday32C = sum(dday32C),
            dday33C = sum(dday33C),
            dday34C = sum(dday34C),
            dday35C = sum(dday35C),
            tmin = mean(tmin),
            tmax = mean(tmax),
            tavg = mean(tavg))
    
# Average over each fips
df <- df %>% 
  group_by(fips, year, month) %>% 
  summarize(dday0C = mean(dday0C),
            dday1C = mean(dday1C),
            dday2C = mean(dday2C),
            dday3C = mean(dday3C),
            dday4C = mean(dday4C),
            dday5C = mean(dday5C),
            dday6C = mean(dday6C),
            dday7C = mean(dday7C),
            dday8C = mean(dday8C),
            dday9C = mean(dday9C),
            dday10C = mean(dday10C),
            dday11C = mean(dday11C),
            dday12C = mean(dday12C),
            dday13C = mean(dday13C),
            dday14C = mean(dday14C),
            dday15C = mean(dday15C),
            dday16C = mean(dday16C),
            dday17C = mean(dday17C),
            dday18C = mean(dday18C),
            dday19C = mean(dday19C),
            dday20C = mean(dday20C),
            dday21C = mean(dday21C),
            dday22C = mean(dday22C),
            dday23C = mean(dday23C),
            dday24C = mean(dday24C),
            dday25C = mean(dday25C),
            dday26C = mean(dday26C),
            dday27C = mean(dday27C),
            dday28C = mean(dday28C),
            dday29C = mean(dday29C),
            dday30C = mean(dday30C),
            dday31C = mean(dday31C),
            dday32C = mean(dday32C),
            dday33C = mean(dday33C),
            dday34C = mean(dday34C),
            dday35C = mean(dday35C),
            tmin = mean(tmin),
            tmax = mean(tmax),
            tavg = mean(tavg))
    df <- filter(df, year >= 1900 & year <= 2012)

    saveRDS(df, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreedays/fips/", x))
}

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/")
infiles <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreedays/fips/")
 
i <- files
i <- setdiff(files, infiles)

library(parallel)
cl <- makeCluster(16)
clusterExport(cl, c("fartocel"))
clusterExport(cl, c("bound_list"))
clusterCall(cl, function() library(dplyr))
parLapply(cl, X = i, fun = comp)
stopCluster(cl)

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreedays/fips/", full.names = TRUE)

library(data.table)
full_degree_days <- rbindlist(lapply(files, readRDS))

# Save fips
library(readr)
library(foreign)
saveRDS(full_degree_days, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.rds")
write_csv(full_degree_days, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.csv")
write.dta(full_degree_days, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.dta")

# For error checking .rds files 
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreedays/fips/", full.names = TRUE) 
test <- as.data.frame(files)
files <- files[1890:3105]

for (i in files){
  df <- readRDS(i)
  print(i)
}


