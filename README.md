![](https://img.shields.io/R/v3.2.3.png?color=red)
![](https://img.shields.io/build/passing.png?color=brightgreen)
![](https://img.shields.io/license/MIT.png?color=blue)

### Fine Scale Weather Data from 1900-2013

-------

**About**

The following repo builds daily gridded weather data for the continental United States from 1900-2013.  The data is allocated to grids and then aggregated to fips (zip codes).  Degree days and degree time are calculated as a result of fine scale weather data.

**Introduction**

Degree days and time in each degree provides a measure of looking at temperature effects during the day.  These measures are used in phenology and by farmers to determine plant development.  Degree days can provide a metric for understanind if it is getting hotter over a time interval.  Degree days can be defined as the amount of time during a day that the environment is exposed to a certain threshold of temperature. For example, suppose for half of the day it is 30°C. A simple calculation of degree days above 25°C would involve 5 degrees for half of a day, so for that particular day the degree days above 25°C would be 2.5. The exposure during the day becomes longer as it becomes warmer or shorter if it is cooler.  Time in each degree is similiar in definition, but instead each degree gets a time interval.  Time in each degree is defined as the length of heat exposure to each one-degree Celsisus temperature interval in each day.  (See Synyder 1985 and ***)

Daily minimum and maximum weather data is needed in order to calculate these two variables.  More importantly, gridded data (2.5 x 2.5 miles) provides a much more accurate relationship to regions and are generally thought of as more precise than using zip codes -- although the grids are aggregated down to zip codes.  This data is not available for the suggested time period so an interpolation technique is used to get to daily data using monthly data.  Calculations of degree days and time in each degree can then be extracted using the necessary mathmatical technique.

Using daily data available from the National Climatic Data Center (NCDC: http://www.ncdc.noaa.gov/) for various weather stations and PRISM (http://www.prism.oregonstate.edu/) data that provides monthly data on a grid a relatively anomaly spline interpolation technique is used to build fine scale weather data on a 2.5 x 2.5 mile grid scale.

The main idea behind building gridded data is to use the monthly temperatures from PRISM, place them at the midpoint (15th day) of each month for each year, and run a spline through each midpoint for each month of each day for each grid.  This will in turn produce fine scale gridded daily data.  Next, find the relative anamoly where R = NCDC(month) / PRISM(month). Finally, use Inverse Distance Weighting (IDW) to find the 5 closest NCDC stations for each PRISM grid to weight the temperature changes and apply the relative anamoly to this weighted temperature.  This will produce gridded 2.5 x 2.5 mile daily data that is between the PRISM and NCDC data.  For a simplegit example in R see [interpolation technique.pdf](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Documentation/interpolation_technique.pdf)

-------

### Download

* Degree Days
 * CSV: [fips_degree_days_1900-2013.csv](https://s3-us-west-1.amazonaws.com/weather.measurements/fips_degree_days_1900-2013.csv) (2.1 GB)
 * STATA: [fips_degree_days_1900-2013.dta](https://s3-us-west-1.amazonaws.com/weather.measurements/fips_degree_days_1900-2013.dta) (1.3 GB)

* Time in each degree
 * CSV: [fips_degree_time_1900-2013.csv](https://s3-us-west-1.amazonaws.com/weather.measurements/fips_degree_time_1900-2013.csv) (233.6 MB)
 * STATA: [fips_degree_time_1900-2013.dta](https://s3-us-west-1.amazonaws.com/weather.measurements/fips_degree_time_1900-2013.dta) (129.4 MB)

* Precipitation
 * CSV: [fips_precipitation_1900-2013.csv](https://s3-us-west-1.amazonaws.com/weather.measurements/fips_precipitation_1900-2013.csv) (123.2 MB)
 * STATA: [fips_precipitation_1900-2013.dta](https://s3-us-west-1.amazonaws.com/weather.measurements/fips_precipitation_1900-2013.dta) (81.7 MB)
 


-------

### Data Setup

The following outlines the procedure for building fine scale weather data.

**Download NCDC and PRISM Data**

1. NCDC
  * Data: ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd_all.tar.gz (2.7 GB as of 12/28/2015)
  * This will download the full data set available in .dly (fixed-width format) format for each station available.  The **README** file contains information on the variables available and how to load the data.  The **STATION** file contains all stations available and their locations of both county and lat/long.  And finally, **INVENTORY** provides all stations available for which years.
  * README: ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
  * STATIONS: ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt
  * INVENTORY: ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt
2. PRISM
  * Data: http://www.prism.oregonstate.edu/historical/     
  * Note: Need to download ppt, tmax, and tmin separately
  * Climate Variable: (1) Precipitation; (2) Minimum Temperature; (3) Maxiumum Temperature
  * Temporal Period: 1895 <= 1895 <= 1980
  * Click: "Download All Historical Data (.bil)" for each climate variable
  * Data: http://www.prism.oregonstate.edu/recent/
  * Click: "Download All Data for All Years (.bil)" for each climate variable
  After downloading all tmax and tmin be sure to unzip each of the files in a separate directory and remove everything except for all files ending in .bil and .hdr; these are the main files needed to extract all the data.  The other files are  .csv files that contain meta data for each grid.
  
**Spline Interpolation and Relative Anamoly Methodology**

The following outlines the methodology for developing fine scale data using spline interpolation of PRISM monthly averages and relative anamoly of NCDC daily data for closest stations.

For a minimum reproducible example in R see an [R Markdown Documentation](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Documentation/interpolation_technique.pdf) and the [R Code](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Documentation/interpolation_technique_example.R).

As discussed above, the main idea is to use a spline to interpolate monthly averages for PRISM and then use the relative anamoly from the inverse distance weight to determine the daily data for each gridded station.  The following two images show the available NCDC stations (black dots) located on a map and all of the gridded stations available with their lat/long coordinates.  Note that PRISM provides many more available stations which will provide more stations for non-linear temperature effects.

![NCDC Stations](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Figures/NCDC_Stations.png)

![PRISM Stations](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Figures/PRISM_Stations.png)


1. Place midpoints of PRISM monthly data
  * Use PRISM monthly temperature averages (tmax and tmin) and place at midpoints, then run a spline through each month of each year for each PRISM grid.  The following graph shows the spline interpolation for 3 months:
![Spline Interpolation](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Figures/Spline_Interpolation.png)
2. Relative Anamoly Interpolation
  * Use the Inverse Distance Weighted (IDW) relative anamoly to further interpolate the data.  The following shows a graph of the interpolated points from IDW and the previous spline:
![RA Interpolation](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Figures/RA_Interpolation.png)

-------

##R Code File Descriptions

  Code should be run in this order.  Deviation from not running in the following order will result in errors and problems with building the data as each of the files depends on the output of the previous.

**Data Setup**

1. [ncdc_convert.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/ncdc_convert.R): Converts and cleans up ncdc data 
  * (1) Subset out NCDC stations with data greater than 1899 and the region
  * (2) Aggregate all the data for each station for each year in NCDC
  * Files Needed: 
    * [ghcnd-stations.csv](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Data/ghcnd-stations.csv)
    * ghcnd-inventory.txt: ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt

2. [prism_convert.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/prism_convert.R): converts and cleans up PRISM data for region
  * (1) Converts ppt, tmax, tmin *.bil to data frame and write as .rds
  * (2) Merge and save each gridNumber for each tmax and tmin to directory
  * File Needed: 
    * [gridInfo.csv](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Data/gridInfo.csv)

3. [lookup.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/lookup.R): Builds three lookup tables: 
  * ncdc_lookup_unique.rds - All unique NCDC stations and locations
  * prism_lookup_unique.rds - All unique PRISM grids and locations
  * prism_nearest.rds - 5 closest NCDC stations for each PRISM grid
  * Files Needed:
    * NCDC_db_sid.csv : from ncdc_convert.R
    * db_tmin_1899-1951.rds : from prism_convert.R

4. [tmax_tmin_interpolation_mc.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/tmax_tmin_interpolation_mc.R): Finds fine scale data using spline interpolation and relative anamoly for tmax and tmin
  * (1) Build data frame for each PRISM and use spline interpolation to get base range
  * (2) Use relative anomaly to adjust base PRISM to NCDC
  * Files Needed:
    * prism_lookup_unique.rds : from lookup.R
    * prism_nearest.rds : from lookup.R
    * ncdc_lookup_unique.rds : from lookup.R
 
5. [base_convert.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/base_convert.R): Merge tmax_tmin for grids and fips
  * (1) Merge tmax_tmin 
  * (2) Merge full grids by fips
  * Files Needed:
    * [gridInfo.csv](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/Data/gridInfo.csv)
    * prism_lookup_unique.rds : from lookup.R

**Parent Folder: Other**

* Calculating degree days
 * [degree_days.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/degree_days.R): calculate degree days from the interpolated fine scale weather data 

* Calculating time in each degree
 * [degree_time.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/degree_time.R): calculate time in each degree from the interpolated fine scale weather data 

* Precipitation
 * [precipitation.R](https://github.com/johnwoodill/Fine-Scale-Weather-Interpolation/blob/master/precipitation.R): aggregates monthly precipitation data from PRISM grids to fips.
   * Files Needed:
     * ppt_1899-2014.rds : from prism_convert.R

-------

### References

Snyder RL (1985) Hand calculating degree days. Agr Forest Meterol 35:353–358.
 



