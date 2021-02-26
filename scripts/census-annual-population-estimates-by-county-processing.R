library(plyr)
library(dplyr)
library(datapkg)
library(tidyr)

##################################################################
#
# Processing Script for Census Annual Population Estimates by County
# Created by Jenna Daly
# On 05/25/2018
#
##################################################################

#Setup environment
sub_folders <- list.files()
raw_location <- grep("raw", sub_folders, value=T)
path_to_raw_data <- (paste0(getwd(), "/", raw_location))
data_location <- grep("data$", sub_folders, value=T)
path_to_data <- (paste0(getwd(), "/", data_location))
pop_df <- dir(path_to_raw_data, recursive=T, pattern = "sub-est2019_9.csv")

pop_est <- read.csv(paste0(path_to_raw_data, "/", pop_df), stringsAsFactors = FALSE, header=T, check.names = F) 
pop_est_CT <- pop_est %>% filter(STNAME == "Connecticut") %>% select(-c(1:8, 10:12)) 

#Remove rows we don't need
pop_est_CT_counties <- pop_est_CT %>% 
  filter(!grepl("Balance|balance| borough| town| city", NAME) )

#Merge in FIPS
county_fips_dp_URL <- 'https://raw.githubusercontent.com/CT-Data-Collaborative/ct-county-list/master/datapackage.json'
county_fips_dp <- datapkg_read(path = county_fips_dp_URL)
fips <- (county_fips_dp$data[[1]])

pop_est_CT_counties <- merge(pop_est_CT_counties, fips, by.x = "NAME", by.y = "County", all.y = T)

#Convert wide to long
pop_est_CT_counties_long <- gather(pop_est_CT_counties, Year, Value, 2:11)

#Clean up year column
pop_est_CT_counties_long$Year <- gsub("POPESTIMATE", "", pop_est_CT_counties_long$Year)

#Assign MT and Variable columns
pop_est_CT_counties_long$`Measure Type` <- "Number"
pop_est_CT_counties_long$Variable <- "Estimated Population"

#Rename and sort columns
pop_est_CT_counties_long <- pop_est_CT_counties_long %>% 
  select(NAME, FIPS, Year, `Measure Type`, Variable, Value) %>% 
  arrange(NAME) %>% 
  dplyr::rename(County = NAME)

# Write to File
write.table(
  pop_est_CT_counties_long,
  file.path(path_to_data, "census-population-by-county-2019.csv"),
  sep = ",",
  row.names = F
)
