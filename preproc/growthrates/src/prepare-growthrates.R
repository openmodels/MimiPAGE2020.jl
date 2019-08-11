#################################### GRAB CONVERGING SSP GROWTH RATES ################################################

rm(list=ls())

library(tidyverse)

years <- c(2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300)

for(scenario in paste0("ssp", 1:5)) {
  # read in the population data and reshape according to csv inputs of PAGE
  df_pop <- read.csv(paste0("data/", scenario, "-pop.csv"), stringsAsFactors = F) %>% filter(year %in% years) %>%
    select(year, region, rate) %>% spread(region, rate) %>%
    select(year, EU, US, OT, EE, CA, IA, AF, LA) # change order of the columns according to PAGE input files
  
  # write into csv file
  write_csv(df_pop, paste0("data/output/", scenario, "_pop_rate.csv"))
  
  # repeat for pcGDP
  df_gdppc <- read.csv(paste0("data/", scenario, "-gdppc.csv"), stringsAsFactors = F) %>% filter(year %in% years) %>%
    select(year, region, rate) %>% spread(region, rate) %>%
    select(year, EU, US, OT, EE, CA, IA, AF, LA) # change order of the columns according to PAGE input files

  # reconstruct GDP growth rates
  df_gdp <- round(df_gdppc + df_pop, 6)
  df_gdp <- df_gdp %>% mutate(year = years[2:10])
  
  # write GDP rates into csv file
  write_csv(df_gdp, paste0("data/output/", scenario, "_gdp_rate.csv"))
  
}
