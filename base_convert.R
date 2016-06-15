# Merge and convert fips

library(data.table)
library(parallel)
library(dplyr)
cl <- makeCluster(16)

### Load grid and fips info for dustbowl region for subsetting
df_fips_grid <- read.csv("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/gridInfo.csv")
df_unique <- readRDS("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/prism_lookup_unique.rds")

df_fips <- left_join(df_unique, df_fips_grid, by = "gridNumber")

### Get all unique fips and and gridNumbers
df_fips <- unique(df_fips$fips)


getfips <- function(x) {
  fips <- filter(df_fips_grid, fips == x)
  grids <- fips$gridNumber
  grids <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/grids/", grids, ".rds")
  df <- rbindlist(lapply(grids, readRDS))
  df <- as.data.frame(df)
  filename <- paste0("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips/", x, ".rds")
  saveRDS(df, filename)
  print(x)
}

i <- df_fips
i <- test$fips
cl <- makeCluster(16)
clusterExport(cl, "df_fips_grid")
clusterCall(cl, function() library(data.table))
clusterCall(cl, function() library(dplyr))
parLapply(cl, X = i, getfips)
stopCluster(cl)

# For finding which didn't process
diff_fips <- list.files("/home/johnw/Projects/Fine-Scale-Weather-Interpolation/Data/Base/tmax_tmin/fips", )
diff_fips <- data.frame(fips = substr(basename(diff_fips), 1, nchar(basename(diff_fips)) - 4))
diff_fips$id <- 1
diff_fips$fips <- as.numeric(as.character(unlist(diff_fips$fips)))
new_df_fips <- data.frame(fips = df_fips)
test <- left_join(new_df_fips, diff_fips, by = "fips")
test <- filter(test, is.na(test$id) == TRUE)

