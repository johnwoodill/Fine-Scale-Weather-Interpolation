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
  col <- paste0("dday_", bound_list[i])
  cadd <- i + nc
  b <- bound_list[i]
  df[,cadd] <- 0
  df[,cadd] <-ifelse(b <= df$tmin, df$tavg - b, 0)
  temp <- acos((2*b - df$tmax - df$tmin)/(df$tmax - df$tmin))
  df[,cadd] <- ifelse(df$tmin < b & b < df$tmax, ((df$tavg - b)*temp + (df$tmax - df$tmin)*sin(temp)/2)/pi, df[,cadd])
  df[,cadd] <- round(df[,cadd], 5)
  colnames(df)[cadd] <- col
}

agg <- df %>% 
  group_by(gridNumber, fips, year, month) %>% 
  summarize(dday_0 = sum(dday_0),
            dday_1 = sum(dday_1),
            dday_2 = sum(dday_2),
            dday_3 = sum(dday_3),
            dday_4 = sum(dday_4),
            dday_5 = sum(dday_5),
            dday_6 = sum(dday_6),
            dday_7 = sum(dday_7),
            dday_8 = sum(dday_8),
            dday_9 = sum(dday_9),
            dday_10 = sum(dday_10),
            dday_11 = sum(dday_11),
            dday_12 = sum(dday_12),
            dday_13 = sum(dday_13),
            dday_14 = sum(dday_14),
            dday_15 = sum(dday_15),
            dday_16 = sum(dday_16),
            dday_17 = sum(dday_17),
            dday_18 = sum(dday_18),
            dday_19 = sum(dday_19),
            dday_20 = sum(dday_20),
            dday_21 = sum(dday_21),
            dday_22 = sum(dday_22),
            dday_23 = sum(dday_23),
            dday_24 = sum(dday_24),
            dday_25 = sum(dday_25),
            dday_26 = sum(dday_26),
            dday_27 = sum(dday_27),
            dday_28 = sum(dday_28),
            dday_29 = sum(dday_29),
            dday_30 = sum(dday_30),
            dday_31 = sum(dday_31),
            dday_32 = sum(dday_32),
            dday_33 = sum(dday_33),
            dday_34 = sum(dday_34),
            dday_35 = sum(dday_35),
            tmin = mean(tmin),
            tmax = mean(tmax),
            tavg = mean(tavg))

saveRDS(agg, paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreedays/", x))
}

files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/")
i <- files

library(parallel)
cl <- makeCluster(20)
clusterExport(cl, c("fartocel"))
clusterCall(cl, function() library(dplyr))
parLapply(cl, X = i, fun = comp)

#rbind together
files <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/degreedays/", full.names = TRUE)
 
library(data.table)
full_degree_days <- rbindlist(lapply(files, readRDS))
 
# Save grids
saveRDS(full_degree_days, "/home/johnw/Dust_Bowl/Data/degree_days/grids_degree_days.rds")
 
