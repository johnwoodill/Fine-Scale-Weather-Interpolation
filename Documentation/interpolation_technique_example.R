######################################################################################################################
#--------------------------------------------------------------------------------------------------------------------
# Author    : A. John Woodill
# Date      : 8/16/2016
# Filename  : interpolation_technique_example.R
# Code      : Example of relative anomaly spline interpolation
#
#--------------------------------------------------------------------------------------------------------------------
######################################################################################################################


library(dplyr)
library(fields)
library(reshape2)
library(ggplot2)

# F to C Conversion
celsiuscon <- function(x) {
  c <- (x-32)/1.8
  return(c)
}

### Data
s1 <- data.frame(id = 1,
                 date = seq(as.Date("2000-01-15"), as.Date("2000-04-15"), "days"), 
                 long = 10 + rep(rnorm(1, mean = 3, sd = 6)), 
                 lat = 40 + rep(rnorm(1, mean = 3, sd = 6)), 
                 temp = rnorm(92, mean = 67.5, sd = 15))

s2 <- data.frame(id = 2, 
                 date = seq(as.Date("2000-01-15"), as.Date("2000-04-15"), "days"), 
                 long = 10 + rep(rnorm(1, mean = 3, sd = 6)), 
                 lat = 40 + rnorm(1, mean = 3, sd = 6),
                 temp = rnorm(92, mean = 67.5, sd = 15))
s3 <- data.frame(id = 3,
                 date = seq(as.Date("2000-01-15"), as.Date("2000-04-15"), "days"), 
                 long = 10 + rep(rnorm(1, mean = 3, sd = 6)), 
                 lat = 40 + rep(rnorm(1, mean = 3, sd = 6)),
                 temp = rnorm(92, mean = 67.5, sd = 15))
s4 <- data.frame(id = 4,
                 date = seq(as.Date("2000-01-15"), as.Date("2000-04-15"), "days"), 
                 long = 10 + rep(rnorm(1, mean = 3, sd = 6)), 
                 lat = 40 + rep(rnorm(1, mean = 3, sd = 6)),
                 temp = rnorm(92, mean = 67.5, sd = 15))

s5 <- data.frame(id = 5,
                 date = seq(as.Date("2000-01-15"), as.Date("2000-04-15"), "days"),  
                 long = 10 + rep(rnorm(1, mean = 3, sd = 6)), 
                 lat = 40 + rep(rnorm(1, mean = 3, sd = 6)),
                 temp = rnorm(92, mean = 67.5, sd = 15))

## Main Station monthly data temps
monthly_df <- data.frame(date = c("2000-01", "2000-02", "2000-03", "2000-04"), 
                  long = 10 + rep(rnorm(1, mean = 3, sd = 6)), 
                  lat = 40 + rep(rnorm(1, mean = 3, sd = 6)),
                  temp = c(70, 64, 72, 65))

# Build fine scale data frame
base <- data.frame(date = seq(as.Date("2000-01-15"), as.Date("2000-04-15"), "days"))

# Apply monthly data to mid points and build separate columns need for spline
monthly_df$date <- as.Date(paste0(monthly_df$date, "-15"))
base$year <- as.numeric(substr(base$date, 1, 4))
base$month <- as.numeric(substr(base$date, 6, 7))
base$day <- as.numeric(substr(base$date, 9, 10))

base <- left_join(base, monthly_df, by = "date")

# Run a spline through each of the midpoints
values_by_date <- splinefun(unique(base[base$day == 15, 1]), base[!is.na(base$temp), 7 ])
base$value <- values_by_date(seq.Date(base$date[1], tail(base$date,1), by = "day"))

# Save spline data for plots below
spline_points <- base$value

# Plot spline interpolation
qplot(base$date, base$value)

# Function to get weights
weights <- function(m_coord, s_coord){
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

# Function to return relative anomaly to apply to base
ra <- function(row_loc, weights){
  s_values <- stack[row_loc:(row_loc+4),6]
  z <- is.na(s_values)
  v <- (weights %*% ifelse(z, 0, s_values)) / (weights %*% !z)
  return(v)
} 

# Stack local stations
stack <- rbind(s1, s2, s3, s4, s5)

# Get IDW weights
m_coord <- base[1,5:6]
s_coord <- data.frame(lat = unique(stack$lat), long = unique(stack$long))
weight <- weights(m_coord, s_coord)

# Find relative anomaly

s1$r <- s1$temp / base$value 
s2$r <- s2$temp / base$value 
s3$r <- s3$temp / base$value 
s4$r <- s4$temp / base$value 
s5$r <- s5$temp / base$value 

# Stack again to get $r local stations
stack <- rbind(s1, s2, s3, s4, s5)

# Need to arrange by date so stack is in daily order
stack <- arrange(stack, date)

# Use both functions to smooth relative anomaly, then apply to base
newval <- sapply(1:nrow(base), function (i) base[i,8] * ra(row_loc = (5*(i-1)+1), weights = weight))
base$value <- newval

# Clean up base
base <- select(base, date, long, lat, value)
base[,2:3 ] <- lapply(base[,2:3], function(x) x[!is.na(x)][1])  # Fill in lat, long

# Plot with ggplot2
plot_data <- data.frame(date = base$date, spline = spline_points, value = base$value)

# Get in ggplot form
df <- melt(plot_data, id = "date")
df$value <- celsiuscon(df$value)
df$value <- df$value - 20
ggplot(subset(df, variable == "spline"), aes(date, value)) + geom_point() + theme_bw() + xlab(NULL) + ylab("Temperature (C)") + ylim(-10,7.5)
ggplot(df, aes(date, value)) + geom_point() + theme_bw() + xlab(NULL) + ylab("Temperature (C)")+ ylim(-10,7.5)
 
