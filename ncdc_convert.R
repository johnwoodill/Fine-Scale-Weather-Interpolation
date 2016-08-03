#########################################################################################################
#-------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 10/27/2015
# Filename  : ncdc_convert.R
# Code      : Converts and cleans up NCDC data
#             (1) Subset out NCDC stations with data greater than 1899 
#             Move appropriate *.dly files to /run/media/john/1TB/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/
#
#             (2) Aggregate all the data for each station for each year in NCDC
#-------------------------------------------------------------------------------------------------------
#########################################################################################################

library(dplyr)
library(readr)
library(rnoaa)
library(maps)
library(reshape2)
library(ggmap)

readDailyInventory <- function(filename = "DailyInv.txt",elements = NULL ){
  
  X <- read.table(filename,col.names = c("Id","Lat","Lon","Element","FirstYear","LastYear"),
                          colClasses = c("character","numeric","numeric","character",
                                        "integer","integer"))
  if (!is.null(elements)){
    dex <- which(X$Element %in% elements)
    X <- X[dex,]
  }
  
  return(X)
}
###############################################################################################################################
#
#  (1) Subset out NCDC stations with data greater than 1899 
#      Move appropriate *.dly files to /run/media/john/1TB/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/
#
###############################################################################################################################

# Load station id
sid <- read.csv("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/ghcnd-stations.csv", stringsAsFactors = FALSE)

# Remove stations outside of U.S. 
sid$state <- map.where("state", sid$long, sid$lat)
sid <- sid[!is.na(sid$state),]

# Check that *.dly files have year at least 2001 and tmax and tmin elements

id <- "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/ghcnd-inventory.txt"
check <- readDailyInventory(id)

colnames(check) <- c("id", "lat", "long", "element", "firstyear", "lastyear")

df <- filter(check, element == "TMAX" | element == "TMIN" | element == "PRCP")
df <- filter(df, firstyear <= 1899 & lastyear >= 2014)                    

#Check on map
map <- get_map(location = "united states", zoom = 3)
mapPoints <- ggmap(map) + geom_point(data = sid, aes(x=long, y = lat))
plot(mapPoints)

# Merge only stations ids with data
sid <- inner_join(df, sid)
sid <- select(sid, id, lat, long, element, firstyear, lastyear, state)
colnames(sid) <- c("id", "lat", "long", "element", "firstyear", "lastyear", "state")

# Remove all files not in required stations
stations <- sid$id

# Check on map where station locations are
map <- get_map(location = "united states", zoom = 5)
mapPoints <- ggmap(map) + geom_point(data = sid, aes(x=long, y = lat)) + ggtitle("NCDC Stations")
plot(mapPoints)

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(unique(stations)), initial = 0)
stepi <- 0

for(i in unique(stations)){
  from <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/ghcnd_all/", i, ".dly")
  to <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/dly/", i , ".dly")
  file.copy(to = to, from = from)
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}

# Save db_sid
write.csv(sid, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC_sid.csv", row.names = FALSE)


###############################################################################################################################
#
#   (2) Aggregate all the data for each station for each year in NCDC
#
###############################################################################################################################

library(reshape2)
library(dplyr)
library(phylin)

### FUNCTIONS

# C to F Conversion
celsiuscon <- function(x) {
  f = x * 1.8 + 32
  return(f)
}

# mm to inches conversion
mmtoin <- function(x) {
  m <- x * 0.0393701
  return(m)
}

# Read in station id data for merge
sid <- read.csv("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC_sid.csv", stringsAsFactors = FALSE)

# Create progress bar as this for loop takes a while
pb <- txtProgressBar(min = 0, max = length(unique(sid$id)), initial = 0)
stepi <- 0

for (i in unique(sid$id)){
  input <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/dly/",i,".dly")
  output <- read.fwf(input, c(11,4,2,4, rep( c(5,-1,-1,-1), 31)))
  colnames(output) <- c("id", "year", "month", "element", "d01", "d02", "d03", "d04", "d05", "d06", "d07", "d08", "d09", "d10", "d11",
                        "d12", "d13", "d14", "d15", "d16", "d17", "d18", "d19", "d20", "d21", "d22", "d23", "d24", "d25", "d26", "d27", "d28",
                        "d29", "d30", "d31")
  # Keep TMAX, TMIN, PRCP, and years between 1899 and 2014
  output <- filter(output,  element %in% c("TMAX", "TMIN", "PRCP"))
  output <- filter(output, year >= 1899 & year <= 2014)
  
  if (length(output[,1]) > 0){
  # Melt to aggregate data
  output <- melt(output, id = c("id", "year", "month", "element"))
  output$month <- sprintf("%02d", output$month)                                 
  output$day <- substr(output$variable, 2,3)
  output$date <- as.Date(paste0(output$year, "-", output$month, "-", output$day))
  output <- select(output, id, element, year, month, day, date, value)
    
  # Convert elements to F values (some are in 1/10 and celcius)
  output <- output %>% 
    group_by(element) %>% 
      mutate(value = ifelse(value == -9999, -9999, ifelse(element == "PRCP", mmtoin(value/10), celsiuscon(value/10))))
  
  
  # Setup output variables
  output <- ungroup(output)
  output$year <- as.numeric(output$year); output$month <- as.numeric(output$month)
  output$day <- as.numeric(output$day); output$element <- as.character(output$element)
  output$id <- as.character(output$id)
  
  # Check that all days are accounted for in a month
  output$month <- sprintf("%02d", output$month)
  output$day <- sprintf("%02d", output$day)
  output$date <- as.Date(paste0(output$year, "-", output$month, "-", output$day))

  # Build new data set to check all dates
  tomerge_1 <- data.frame(date = seq(as.Date("1899-12-15"), as.Date("2013-1-15"), "days"), element = "TMAX")
  tomerge_2 <- data.frame(date = seq(as.Date("1899-12-15"), as.Date("2013-1-15"), "days"), element = "TMIN")
  tomerge_3 <- data.frame(date = seq(as.Date("1899-12-15"), as.Date("2013-1-15"), "days"), element = "PRCP")
  tomerge <- rbind(tomerge_1, tomerge_2, tomerge_3)
  newdat <- merge(tomerge, output, by = c("date", "element"), all.x = TRUE)
  newdat <- select(newdat, id, element, year, month, day, date, value)
  newdat <- arrange(newdat, id)
  newdat$id <- newdat[1,1]
  newdat$year <- substr(newdat$date, 1, 4)
  newdat$month <- substr(newdat$date, 6, 7)
  newdat$day <- substr(newdat$date, 9, 10)
  newdat$value <- round(newdat$value, 2)
  newdat[newdat == -9999] <- NA
  
  
  if (nrow(output) > 0 | all(is.na(newdat$value)) == FALSE){
    # Save RDS
    filename <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/", i, ".rds")
    saveRDS(newdat, filename)
    } else {
      db_sid <- filter(db_sid, id != i)   
    }
  }
  stepi = stepi + 1
  setTxtProgressBar(pb, stepi)
}


  
length(list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/"))

# Remove those stations with no data from db_sid 
ncdc_list <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC/rds/")
ncdc_list <- substr(ncdc_list, 1, 11)
sid <- filter(sid, id %in% ncdc_list)

write.csv(sid, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC_sid.csv", row.names = FALSE)
sid <- read.csv("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/NCDC_sid.csv", stringsAsFactors = FALSE)
