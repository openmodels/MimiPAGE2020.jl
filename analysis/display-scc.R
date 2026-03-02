setwd("~/research/iamup2/MimiPAGE2020.jl/analysis")

sccs <- read.csv("../output/allscc-nodrupp.csv")

library(ggplot2)
library(scales)
library(dplyr)

quantile(sccs$scc[sccs$country == 'global'])
mean(sccs$scc[sccs$country == 'global'])
ggplot(subset(sccs, country == "global"), aes(scc)) +
    geom_histogram()

quantile(sccs$scc[sccs$country == 'KOR'])
mean(sccs$scc[sccs$country == 'KOR'])
ggplot(subset(sccs, country == "KOR"), aes(scc)) +
    geom_histogram()

sccs2 <- read.csv("../output/allscc.csv")
ggplot(subset(sccs2, country == "KOR"), aes(scc)) +
    geom_histogram()

pdf <- rbind(cbind(panel="Drupp et al. Median", subset(sccs, country == "KOR")),
             cbind(panel="Drupp et al. Range", subset(sccs2, country == "KOR")))
## pdf$scc.2023 <- pdf$scc * 122.265 / 97.315

ggplot(pdf) +
    coord_cartesian(xlim=c(-2, 50)) +
    facet_wrap(~ panel, ncol=1) +
    geom_histogram(aes(scc), bins=100) +
    geom_vline(data=pdf %>% group_by(panel) %>% summarize(value=c(median(scc), mean(scc)), stat=c("Median", "Mean")),
               aes(xintercept=value, colour=stat)) +
    scale_colour_discrete("Statistic:") +
    xlab("Domestic social cost of carbon (2023 USD)") + ylab("Monte Carlo draws") +
    theme_bw()
ggsave("../scchist-kor.pdf", width=6.5, height=5)

sum((subset(sccs, country != "global") %>% group_by(country) %>% summarize(scc.mu=mean(scc)))$scc.mu)

pdf %>% group_by(panel) %>% summarize(scc.mean=mean(scc), scc.median=median(scc),
                                      scc.25=quantile(scc, .25), scc.75=quantile(scc, .75))

source("map.R")

gp <- make.map(sccs %>% group_by(country) %>% summarize(scc=median(scc)),
               'country', 'scc', "Social Cost of Carbon\n(2015 USD / t CO2)")
ggsave("../sccmap.pdf", width=10, height=5.5)

sccs <- read.csv("../src/allscc-nodrupp-2050.csv")
sum((subset(sccs, country != "global") %>% group_by(country) %>% summarize(scc.mu=mean(scc)))$scc.mu)

sccs <- read.csv("../src/allscc-nodrupp-2100.csv")
sum((subset(sccs, country != "global") %>% group_by(country) %>% summarize(scc.mu=mean(scc)))$scc.mu)

sccs <- read.csv("../output/allscc-2100-v2.csv")
topcolval <- quantile((sccs %>% group_by(country) %>% summarize(scc=median(scc, na.rm=T)))$scc, .995)

gp <- make.map(sccs %>% group_by(country) %>% summarize(scc=median(scc, na.rm=T)),
               'country', 'scc', "Social Cost of Carbon\n(2015 USD / t CO2)", topcolval=topcolval) +
    scale_fill_distiller("Social Cost of Carbon\n(2015 USD / t CO2)", limits=c(0.01, topcolval), breaks=c(0.01, 0.1, 1, 10, 100), palette="YlOrRd", direction=1, labels=scales::comma, trans='log10')
ggsave("national/sccmap-2100.pdf", width=10, height=5.5)

sccs <- read.csv("../output/allscc.csv")

gp <- make.map(sccs %>% group_by(country) %>% summarize(scc=median(scc, na.rm=T)),
               'country', 'scc', "Social Cost of Carbon\n(2015 USD / t CO2)", topcolval=topcolval) +
    scale_fill_distiller("Social Cost of Carbon\n(2015 USD / t CO2)", limits=c(0.01, topcolval), breaks=c(0.01, 0.1, 1, 10, 100), palette="YlOrRd", direction=1, labels=scales::comma, trans='log10')
ggsave("national/sccmap-col2100.pdf", width=10, height=5.5)

