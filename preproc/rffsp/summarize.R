## setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/rffsp/")

library(dplyr)

baseline <- read.csv("../../data/bycountry.csv")
aggdefs <- read.csv("../../data/aggregates.csv")

files <- list.files("RFF_Probabilistic_POP_GDP")

results <- data.frame()
for (ii in 1:length(files)) {
    print(ii)
    projs <- read.csv(file.path("RFF_Probabilistic_POP_GDP", files[ii]))
    projs2 <- projs %>% left_join(aggdefs, by=c('Country'='ISO'))
    names(projs2)[names(projs2) == 'Country'] <- "ISO"
    projs3.aggs <- subset(projs2, !is.na(Aggregate)) %>% group_by(Year, Aggregate) %>%
        summarize(Population.thousands.=sum(Population.thousands.), GDP.millions.of.2011.USD.=sum(GDP.millions.of.2011.USD.))
    names(projs3.aggs)[names(projs3.aggs) == 'Aggregate'] <- "ISO"

    subbase <- subset(baseline, ISO3 %in% projs$Country | ISO3 %in% projs3.aggs$ISO)

    projs3 <- rbind(data.frame(Year=2015, ISO=subbase$ISO3, Population.thousands.=1000*subbase$Pop2015, GDP.millions.of.2011.USD.=subbase$GDP2015 * 94.00427/100),
                    subset(projs2, is.na(Aggregate))[, c('Year', 'ISO', 'Population.thousands.', 'GDP.millions.of.2011.USD.')], projs3.aggs)

    period <- c(2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300)
    starts <- c(2015, 2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250)
    ends <- c(2025, 2040, 2050, 2060, 2100, 2125, 2200, 2250, 2300, 2300)
    ## v = a exp(gt)  => log(v) = a' + gt

    for (pp in 1:length(period)) {
        years <- seq(starts[pp], ends[pp], by=5)
        df2 <- projs3 %>% group_by(ISO) %>% summarize(pop.grow=coef(lm(log(Pop) ~ Year,
                                                                       data=data.frame(Year=years, Pop=Population.thousands.[Year >= starts[pp] & Year <= ends[pp]])))[2],
                                                      gdppc.grow=coef(lm(log(GDPpc) ~ Year,
                                                                         data=data.frame(Year=years, GDPpc=(GDP.millions.of.2011.USD. / Population.thousands.)[Year >= starts[pp] & Year <= ends[pp]])))[2])
        results <- rbind(results, cbind(num=ii, period=period[pp], df2))
    }
}

## write.csv(results, "../../data/rffsp.csv", row.names=F)

for (start in seq(1, by=1000, 10000))
    arrow::write_feather(subset(results, num >= start & num < start + 1000), paste0("../../data/rffsp/grows-", (start-1) / 1000 + 1, ".feather"))

results2 <- results %>% group_by(period, ISO) %>% summarize(pop.grow=mean(pop.grow), gdppc.grow=mean(gdppc.grow))
arrow::write_feather(results2, paste0("../../data/rffsp/grows-mean.feather"))
