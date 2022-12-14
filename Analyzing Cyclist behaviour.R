

# Install required packages
install.packages("tidyverse")  # tidyverse for data import and wrangling
install.packages("lubridate")  # lubridate for date functions
install.packages("ggplot2")    # ggplot for visualization
install.packages("readxl")     # readxl for uploading excel files
install.packages("janitor")

library(tidyverse)  #helps wrangle data
library(lubridate)  #helps wrangle date attributes
library(ggplot2)    #helps visualize data
library(readxl)     #helps to read excel file
library(janitor)

#=====================
# STEP 1: COLLECT DATA
#=====================
# Upload Divvy datasets (xlsx files) here
# Here I have added columns for ride_length and day_of_week from excel sheet itself

tripdata_2021_oct <- read_excel('202110-divvy-tripdata.xlsx')
tripdata_2021_nov <- read_excel('202111-divvy-tripdata.xlsx')
tripdata_2021_dec <- read_excel('202112-divvy-tripdata.xlsx')
tripdata_2022_jan <- read_excel('202201-divvy-tripdata.xlsx')
tripdata_2022_feb <- read_excel('202202-divvy-tripdata.xlsx')
tripdata_2022_mar <- read_excel('202203-divvy-tripdata.xlsx')
tripdata_2022_apr <- read_excel('202204-divvy-tripdata.xlsx')
tripdata_2022_may <- read_excel('202205-divvy-tripdata.xlsx')
tripdata_2022_jun <- read_excel('202206-divvy-tripdata.xlsx')
tripdata_2022_jul <- read_excel('202207-divvy-tripdata.xlsx')
tripdata_2022_aug <- read_excel('202208-divvy-tripdata.xlsx')
tripdata_2022_sep <- read_excel('202209-divvy-tripdata.xlsx')

#====================================================
# STEP 2: WRANGLE DATA AND COMBINE INTO A SINGLE FILE
#====================================================
# Compare column names each of the files
# checking the datatypes are consistent in all sheets

str(tripdata_2021_oct)
str(tripdata_2021_nov)
str(tripdata_2021_dec)
str(tripdata_2022_jan)
str(tripdata_2022_feb)
str(tripdata_2022_mar)
str(tripdata_2022_apr)
str(tripdata_2022_may)
str(tripdata_2022_jun)
str(tripdata_2022_jul)
str(tripdata_2022_aug)
str(tripdata_2022_sep) # end_station_id was found to be in num data type. so it has to be converted to chr

#converting end_station_id of sep_2022 to chr
tripdata_2022_sep <- mutate(tripdata_2022_sep,
  end_station_id = as.character(end_station_id))

tripdata_combined <- bind_rows(
                              tripdata_2021_oct,
                              tripdata_2021_nov,
                              tripdata_2021_dec,
                              tripdata_2022_jan,
                              tripdata_2022_feb,
                              tripdata_2022_mar,
                              tripdata_2022_apr,
                              tripdata_2022_may,
                              tripdata_2022_jun,
                              tripdata_2022_jul,
                              tripdata_2022_aug,
                              tripdata_2022_sep
                              )

#======================================================
# STEP 3: CLEAN UP AND ADD DATA TO PREPARE FOR ANALYSIS
#======================================================
# Inspect the new table that has been created
colnames(tripdata_combined) #List of column names
nrow(tripdata_combined)     #How many rows are in data frame?
dim(tripdata_combined)      #Dimensions of the data frame?
head(tripdata_combined)     #See the first 6 rows of data frame.  Also tail(all_trips)
str(tripdata_combined)      #See list of columns and data types (numeric, character, etc)
summary(tripdata_combined)  #Statistical summary of data. Mainly for numerics

# Finding the ride_length and converting into seconds
tripdata_combined$ride_length <- difftime(
                                          tripdata_combined$ended_at, 
                                          tripdata_combined$started_at,
                                          units = "secs"
                                          )

# converting ride_length data type from 'difftime' num to num

tripdata_combined$ride_length <- as.numeric(tripdata_combined$ride_length)

# Add columns that list the date, month, day, and year of each ride
# This will allow us to aggregate ride data for each month, day, or year .before completing these operations we could only aggregate at the ride level

tripdata_combined$date <- as.Date(tripdata_combined$started_at)               #The default format is yyyy-mm-dd
tripdata_combined$month <- format(as.Date(tripdata_combined$date), "%m")
tripdata_combined$day <- format(as.Date(tripdata_combined$date), "%d")
tripdata_combined$year <- format(as.Date(tripdata_combined$date), "%Y")
tripdata_combined$day_of_week <- format(as.Date(tripdata_combined$date), "%A")

# Remove "bad" data
# The dataframe includes a few entries when bikes were taken out of docks and checked for quality by Divvy or ride_length was negative
# We will create a new version of the dataframe (all_data) since data is being removed
all_trips <- tripdata_combined %>% filter(ride_length>=0) %>% filter(start_station_name != "HQ QR")

# STEP 4: CONDUCT DESCRIPTIVE ANALYSIS
#=====================================
# Descriptive analysis on ride_length (all figures in seconds)
mean(all_trips$ride_length) #straight average (total ride length / rides)
median(all_trips$ride_length) #midpoint number in the ascending array of ride lengths
max(all_trips$ride_length) #longest ride
min(all_trips$ride_length) #shortest ride

# Compare members and casual users
aggregate(all_trips$ride_length ~ all_trips$member_casual, FUN = mean)
aggregate(all_trips$ride_length ~ all_trips$member_casual, FUN = median)
aggregate(all_trips$ride_length ~ all_trips$member_casual, FUN = max)
aggregate(all_trips$ride_length ~ all_trips$member_casual, FUN = min)

# See the average ride time by each day for members vs casual users
aggregate(all_trips$ride_length ~ all_trips$member_casual + all_trips$day_of_week, FUN = mean)

# Notice that the days of the week are out of order. Let's fix that.
all_trips$day_of_week <- ordered(all_trips$day_of_week, levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))

# Now, let's run the average ride time by each day for members vs casual users
aggregate(all_trips$ride_length ~ all_trips$member_casual + all_trips$day_of_week, FUN = mean)

# analyze ridership data by type and weekday
all_trips %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  # creates weekday field using wday()
  group_by(member_casual, weekday) %>%                  # groups by usertype and weekday
  summarise(number_of_rides = n()						          	# calculates the number of rides and average duration 
            ,average_duration = mean(ride_length)) %>% 	# calculates the average duration
  arrange(member_casual, weekday)							         	# sorts

# Let's visualize the number of rides by rider type
all_trips %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

# Let's create a visualization for average duration
all_trips%>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")


#=================================================
# STEP 5: EXPORT SUMMARY FILE FOR FURTHER ANALYSIS
#=================================================
# Create a csv file that we will visualize in Excel, Tableau, or my presentation software
# N.B.: If you are working on a PC, change the file location accordingly (most likely "C:\Users\YOUR_USERNAME\Desktop\...") to export the data.
counts <- aggregate(all_trips$ride_length ~ all_trips$member_casual + all_trips$day_of_week, FUN = mean)
write.csv(counts, file = 'E:/MTECH/MySQL/Google data analytics/Case study 1- bike share/R/avg_ride_length.csv')


