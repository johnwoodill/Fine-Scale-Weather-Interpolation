### Building Fine Scale Weather Data from 1900-2013

**About**

The following repo builds daily gridded weather data for the continental United States from 1900-2013.  The data is allocated to grids and then aggregated to fips (zip codes).  Degree days and degree time are calculated as a result of fine scale weather data.

**Introduction**

In order to determine non-linear temperature effects fine scale (daily) gridded weather data needs to be available.  Unfortunately, this data does not exist for the historical time period 1900-1950.  There are daily data available from the National Climatic Data Center (NCDC: http://www.ncdc.noaa.gov/) for various weather stations, but it is sparse and not consistent across days.

PRISM (http://www.prism.oregonstate.edu/) data is some of the best weather data available and is gridded on 2.5 x 2.5 mile scale across the same region. Daily data is not available, but monthly data is.  In order to build fine scale weather data both NCDC and PRISM data sets will be used.  

The main idea behind building gridded data is to use the monthly temperatures from PRISM, place them at the midpoint (15th day) of each month for each year, and run a spline through each midpoint for each month of each day for each grid.  This will in turn produce fine scale gridded daily data.  Next, find the relative anamoly where R = NCDC(month) / PRISM(month). Finally, use Inverse Distance Weighting (IDW) to find the 5 closest NCDC stations for each PRISM grid to weight the temperature changes and apply the relative anamoly to this weighted temperature.  This will produce gridded 2.5 x 2.5 mile daily data that is between the PRISM and NCDC data.

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

##R Code File Descriptions

  Code should be run in this order.  Deviation from not running in the following order will result in errors and problems with building the data as each of the files depends on the output of the previous.

**Data Setup Folder**

1. [ncdc_convert.R](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/ncdc_convert.R): Converts and cleans up ncdc data for Dust Bowl region
  * (1) Subset out NCDC stations with data greater than 1899 and the region
  * (2) Aggregate all the data for each station for each year in NCDC
  * Files Needed: 
    * [ghcnd-stations.csv](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/ghcnd-stations.csv)
    * [ghcnd-inventory.txt](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/ghcnd-inventory.txt)

2. [prism_convert.R](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/prism_convert.R): converts and cleans up PRISM data for region
  * (1) Converts ppt, tmax, tmin *.bil to data frame and write as .rds
  * (2) Merge and save each gridNumber for each tmax and tmin to directory
  * File Needed: 
    * [gridInfo.csv](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/gridInfo.csv)

3. [lookup.R](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/lookup.R): Builds three lookup tables: 
  * ncdc_lookup_unique.rds - All unique NCDC stations and locations
  * prism_lookup_unique.rds - All unique PRISM grids and locations
  * prism_nearest.rds - 5 closest NCDC stations for each PRISM grid
  * Files Needed:
    * NCDC_db_sid.csv : from ncdc_convert.R
    * db_tmin_1899-1951.rds : from prism_conver.R

4. [tmax_tmin_interpolation.R](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/tmax_tmin_interpolation.R): Finds fine scale data using spline interpolation and relative anamoly for tmax and tmin
  * (1) Build data frame for each PRISM and use spline interpolation to get base range
  * (2) Use relative anomaly to adjust base PRISM to NCDC
  * Files Needed:
    * prism_lookup_unique.rds : from lookup.R
    * prism_nearest.rds : from lookup.R
    * ncdc_lookup_unique.rds : from lookup.R
 
5. [ppt_interpolation.R](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/ppt_interpolation.R): Finds fine scale data using spline interpolation and relative anamoly for ppt
  * (1) Build data frame for each PRISM and use spline interpolation to get base range
  * (2) Use relative anomaly to adjust base PRISM to NCDC
  * Files Needed:
    * prism_lookup_unique.rds : from lookup.R
    * prism_nearest.rds : from lookup.R
    * ncdc_lookup_unique.rds : from lookup.R 

6. [base_convert.R](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/base_convert.R): Merge tmax_tmin and ppt for grids and fips
  * (1) Merge tmax_tmin and ppt grids
  * (2) Merge full grids by fips
  * Files Needed:
    * [gridInfo.csv](https://github.com/johnwoodill/Non-Linear-Temperature-Effects-of-the-Dust-Bowl/blob/master/Data%20Setup/gridInfo.csv)
    * prism_lookup_unique.rds : from lookup.R


 



