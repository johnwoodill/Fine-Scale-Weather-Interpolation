library(parallel)
library(dplyr)
library(data.table)
library(tidyr)
library(ggplot2)

# Aggregate NCDC Data
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/")

comp <- function(x){
  dat <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/",x))
  dat <- dat %>% 
    group_by(element, year) %>% 
    summarise(value = mean(value, na.rm = TRUE))
  saveRDS(dat, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Verify/NCDC/", x))
}

cl <- makeCluster(16)
i <- files
clusterCall(cl, function() library(dplyr))
parLapply(cl, X = i, fun = comp)
stopCluster(cl)

# Aggregate PRISM Data
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/gridNumber/")

comp <- function(x){
  dat <- readRDS(paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/gridNumber/",x))
  dat <- dat %>% 
    group_by(element, year) %>% 
    summarise(mean = mean(mean, na.rm = TRUE))
  saveRDS(dat, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Verify/PRISM/", x))
}

cl <- makeCluster(16)
i <- files
clusterCall(cl, function() library(dplyr))
parLapply(cl, X = i, fun = comp)
stopCluster(cl)

# bind together
ncdc_s <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Verify/NCDC/", full.names = TRUE)
ncdc <- rbindlist(lapply(ncdc_s, readRDS))
ncdc <- filter(ncdc, element != "PRCP")
ncdc <- ncdc %>% 
  group_by(element, year) %>% 
  summarise(mean = mean(value, na.rm = TRUE))
ncdc <- spread(ncdc, element, mean)
ncdc$tavg <- (ncdc$TMAX + ncdc$TMIN)/2
ncdc$type <- "NCDC"
names(ncdc) <- tolower(names(ncdc))

prism_list <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Verify/PRISM/", full.names = TRUE)
prism <- rbindlist(lapply(prism_list, readRDS))
prism <- filter(prism, element != "ppt")
prism2 <- prism %>% 
  group_by(element, year) %>% 
  summarise(mean = mean(mean, na.rm = TRUE))
prism2 <- spread(prism2, element, mean)
prism2$tavg <- (prism2$tmax + prism2$tmin)/2
prism2$type <- "PRISM"

# Get degree days interpolated
base <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_degree_days_1900-2013.rds")
base <- select(base, year, tmax, tmin, tavg)
base <- gather(base, element, value, -year)
base <- base %>% 
  group_by(element, year) %>% 
  summarise(mean = mean(value, na.rm = TRUE))
base <- spread(base, element, mean)
base$type <- "BASE"

dat <- rbind(base, ncdc, prism2)

ggplot(dat, aes(year, tavg, color = type)) + geom_smooth()
