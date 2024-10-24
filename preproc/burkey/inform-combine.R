setwd("~/Dropbox/Country-Level PAGE/Damages")

library(readxl)
library(reshape2)
library(countrycode)
library(dplyr)

icc <- read_xlsx("INFORM2022_TREND_2013_2022_v063_ALL.xlsx")
icc <- subset(icc, IndicatorName %in% c('INFORM Risk Index', 'Hazard & Exposure Index', 'Vulnerability Index', 'Lack of Coping Capacity Index'))
icc.2015 <- dcast(subset(icc, INFORMYear == 2015), Iso3 ~ IndicatorId, value.var='IndicatorScore')
icc.2020 <- dcast(subset(icc, INFORMYear == 2020), Iso3 ~ IndicatorId, value.var='IndicatorScore')
icc.2022 <- dcast(subset(icc, INFORMYear == 2022), Iso3 ~ IndicatorId, value.var='IndicatorScore')
icc.2023 <- dcast(subset(icc, INFORMYear == 2023), Iso3 ~ IndicatorId, value.var='IndicatorScore')

icc.fut <- read_xlsx("INFORM CC Brochure data.xlsx", skip=4)
icc.fut <- data.frame(Country=icc.fut$Country, Change.2050.Pess=icc.fut$`Change in risk...4`, Change.2050.Opt=icc.fut$`Change in risk...7`,
                      Change.2080.Pess=icc.fut$`Change in risk...10`, Change.2080.Opt=icc.fut$`Change in risk...13`)
icc.fut$Iso3 <- countrycode(icc.fut$Country, origin='country.name', destination='iso3c')
icc.fut$Iso3[icc.fut$Country == 'Micronesia'] <- 'FSM'
icc.fut$Iso3[icc.fut$Country == 'Türkiye'] <- 'TUR'

icc.fut2 <- icc.fut %>% left_join(icc.2022, by='Iso3')
icc.fut2$HA.2050.Pess <- icc.fut2$HA + icc.fut2$Change.2050.Pess
icc.fut2$HA.2050.Opt <- icc.fut2$HA + icc.fut2$Change.2050.Opt
icc.fut2$HA.2080.Pess <- icc.fut2$HA + icc.fut2$Change.2080.Pess
icc.fut2$HA.2080.Opt <- icc.fut2$HA + icc.fut2$Change.2080.Opt

icc2 <- icc.2015 %>% left_join(icc.2020, by='Iso3', suffix=c('', '.2020')) %>%
    left_join(icc.2023, by='Iso3', suffix=c('.2015', '.2023')) %>%
    left_join(icc.fut2[, c('Country', 'Iso3', 'HA.2050.Pess', 'HA.2050.Opt', 'HA.2080.Pess', 'HA.2080.Opt')], by='Iso3')
names(icc2)[1] <- 'ISO'

write.csv(icc2, "inform-combined.csv", row.names=F)
