setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/slr")

library(reshape2)
library(dplyr)

load("totalcosts.RData")

## Drop the non-market components: wetland, stormPopulation
df.costs <- df %>% group_by(adm0, ssp, case, quantile, year) %>% summarize(damages=sum(costs[costtype %in% c('inundation', 'stormCapital')]), adaptcost=sum(costs[costtype %in% c('relocation', 'protection')]))
df.slr <- read.csv("slr-ssp.csv")

library(ggplot2)
ggplot(df.costs %>% group_by(year) %>% summarize(damages=sum(damages), adaptcost=sum(adaptcost)), aes(year)) +
    geom_line(aes(y=damages, linetype="Damages")) + geom_line(aes(y=adaptcost, linetype="Adaptation Costs"))

df.slr$quantiles <- round(df.slr$quantiles, 2)
df.costs$ssp <- substring(df.costs$ssp, 1, 6)
df <- subset(df.costs, year >= 2010) %>% left_join(df.slr, by=c('quantile'='quantiles', 'ssp', 'year'='years')) %>%
    filter(!is.na(sea_level_change))

ggplot(df %>% filter(quantile == 0.5) %>% group_by(year, ssp, case) %>% summarize(costs=sum(damages + adaptcost), sea_level_change=sea_level_change[1]), aes(sea_level_change, costs, group=paste(ssp, case))) +
    geom_line(aes(colour=ssp, linetype=case))

## Divide by country GDP
sspdata <- subset(read.csv("gdp.csv"), MODEL == "OECD Env-Growth") # billion US$2005/yr vs. $2019 USD for pyCIAM; chose OECD because more countries
sspdata <- sspdata[, c(2, 3, 9:ncol(sspdata))]
sspdata2 <- melt(sspdata, c('SCENARIO', 'REGION'), variable.name='Xyear', value.name='gdp')
sspdata2$gdp <- sspdata2$gdp * 104.004 / 89.629 # From https://fred.stlouisfed.org/series/GDPDEF#0
sspdata2$sspnum <- substring(sspdata2$SCENARIO, 4, 4)
sspdata2$year <- as.numeric(substring(sspdata2$Xyear, 2, 5))

df$sspnum <- substring(df$ssp, 4, 4)
df2 <- df %>% left_join(sspdata2, by=c('sspnum', 'year', 'adm0'='REGION'))
df2$damages.frac <- df2$damages / (df2$gdp * 1e9)
df2$adaptcost.frac <- df2$adaptcost / (df2$gdp * 1e9)

ggplot(df2 %>% filter(quantile == 0.5) %>% group_by(year, ssp, case) %>% summarize(costs=mean(damages.frac + adaptcost.frac, na.rm=T), sea_level_change=sea_level_change[1]), aes(sea_level_change, costs, group=paste(ssp, case))) +
    geom_line(aes(colour=ssp, linetype=case))

df3 <- subset(df2, !is.na(gdp))

library(nnls)
df3$sea_level_change2 <- df3$sea_level_change^2
## results <- df3 %>% group_by(adm0, case) %>% summarize(alpha=lm(costs ~ 0 + sea_level_change + sea_level_change2)$coef[1],
##                                                      beta=lm(costs ~ 0 + sea_level_change + sea_level_change2)$coef[2])

opts <- nrow(unique(df3[, c('ssp', 'quantile', 'year')]))
allres <- data.frame()
for (bs in 1:100) {
    print(bs)
    rows <- sample(opts, replace=T)
    results <- df3 %>% group_by(adm0) %>% summarize(alpha.damage.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                        sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                  damages.frac[case == 'noAdaptation'][rows]))[1],
                                                   beta.damage.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                       sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                 damages.frac[case == 'noAdaptation'][rows]))[2],
                                                   alpha.damage.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                        sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                  damages.frac[case == 'optimalfixed'][rows]))[1],
                                                   beta.damage.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                       sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                 damages.frac[case == 'optimalfixed'][rows]))[2],
                                                   alpha.adapts.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                        sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                  adaptcost.frac[case == 'noAdaptation'][rows]))[1],
                                                   beta.adapts.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                       sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                 adaptcost.frac[case == 'noAdaptation'][rows]))[2],
                                                   alpha.adapts.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                        sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                  adaptcost.frac[case == 'optimalfixed'][rows]))[1],
                                                   beta.adapts.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                       sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                 adaptcost.frac[case == 'optimalfixed'][rows]))[2])
    allres <- rbind(allres, cbind(bs=bs, results))
}

write.csv(allres, "../../data/damages/slremul.csv", row.names=F)
