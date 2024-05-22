setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/slr")

library(dplyr)

load("totalcosts.RData")

df.costs <- df %>% group_by(adm0, ssp, case, quantile, year) %>% summarize(damages=sum(costs[costtype %in% c('wetland', 'inundation', 'stormCapital', 'stormPopulation')]), adaptcost=sum(costs[costtype %in% c('relocation', 'protection')]))
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

library(nnls)
df$sea_level_change2 <- df$sea_level_change^2
## results <- df %>% group_by(adm0, case) %>% summarize(alpha=lm(costs ~ 0 + sea_level_change + sea_level_change2)$coef[1],
##                                                      beta=lm(costs ~ 0 + sea_level_change + sea_level_change2)$coef[2])

opts <- nrow(unique(df[, c('ssp', 'quantile', 'year')]))
allres <- data.frame()
for (bs in 1:100) {
    print(bs)
    rows <- sample(opts, replace=T)
    results <- df %>% group_by(adm0) %>% summarize(alpha.damage.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                        sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                  damages[case == 'noAdaptation'][rows]))[1],
                                                   beta.damage.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                       sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                 damages[case == 'noAdaptation'][rows]))[2],
                                                   alpha.damage.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                        sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                  damages[case == 'optimalfixed'][rows]))[1],
                                                   beta.damage.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                       sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                 damages[case == 'optimalfixed'][rows]))[2],
                                                   alpha.adapts.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                        sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                  adaptcost[case == 'noAdaptation'][rows]))[1],
                                                   beta.adapts.noadapt=coef(nnls(cbind(sea_level_change[case == 'noAdaptation'][rows],
                                                                                       sea_level_change2[case == 'noAdaptation'][rows]),
                                                                                 adaptcost[case == 'noAdaptation'][rows]))[2],
                                                   alpha.adapts.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                        sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                  adaptcost[case == 'optimalfixed'][rows]))[1],
                                                   beta.adapts.optimal=coef(nnls(cbind(sea_level_change[case == 'optimalfixed'][rows],
                                                                                       sea_level_change2[case == 'optimalfixed'][rows]),
                                                                                 adaptcost[case == 'optimalfixed'][rows]))[2])
    allres <- rbind(allres, cbind(bs=bs, results))
}

write.csv(allres, "../../data/damages/slremul.csv", row.names=F)
