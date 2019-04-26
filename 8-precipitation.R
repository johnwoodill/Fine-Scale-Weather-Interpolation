######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 8/16/2016
# Filename  : precipitation.R
# Code      : Monthly precipitation from PRISM
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################

library(dplyr)
library(reshape2)
library(readr)
library(foreign)

mo2Num <- function(x) match(tolower(x), tolower(month.abb))

# Load precipitation data frame from PRISM
df_ppt <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/PRISM/ppt/ppt_1899-2014.rds")

# Melt from wide to long
temp_df_ppt <- melt(df_ppt, id = c("fips", "county_name", "state", "gridNumber", "cropArea", "lat", "long", "year"))

# Aggregate
temp_df_ppt <- temp_df_ppt %>% 
  group_by(fips, year, variable) %>% 
  summarise(ppt = mean(value))

# Cleanup
names(temp_df_ppt) <- c("fips", "year", "month", "ppt")
temp_df_ppt$month <- mo2Num(temp_df_ppt$month)
temp_df_ppt <- filter(temp_df_ppt, year >= 1900 & year <= 2014)

# Save fips

saveRDS(temp_df_ppt, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_precipitation_1900-2013.rds")
write_csv(temp_df_ppt, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_precipitation_1900-2013.csv")
write.dta(temp_df_ppt, "/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/fips_precipitation_1900-2013.dta")

