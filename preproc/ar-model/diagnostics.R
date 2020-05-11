setwd("~/research/iamup/mimi-page-2020.jl/preproc/ar-model")

df.co2.hist <- read.csv("co2conc.csv")
df.co2.obs <- read.table("co2_annmean_gl.txt")
names(df.co2.obs) <- c('year', 'mean', 'unc')
df.co2 <- data.frame(year=c(df.co2.hist$year[df.co2.hist$year < min(df.co2.obs$year)], df.co2.obs$year), co2=c(df.co2.hist$rcp45[df.co2.hist$year < min(df.co2.obs$year)], df.co2.obs$mean), co2.unc=c(seq(10, 1, length.out=sum(df.co2.hist$year < min(df.co2.obs$year))), df.co2.obs$unc))

df.temp <- as.data.frame(t(as.matrix(read.csv("region-temps.csv", header=F))))
colnames(df.temp) <- c('eu', 'rus+', 'usa', 'chi+', 'ind+', 'afr', 'lat', 'oth')
df.temp$year <- 1850:2018

ampf <- c(1.27, 1.65, 1.34, 1.17, 1.01, 1.21, 1.04, 1.22)
## RT = GMST * AMPF: use mean of multiple observations
df.temp$gmst <- NA
for (ii in 1:nrow(df.temp))
    df.temp$gmst[ii] <- mean(as.numeric(df.temp[ii, -9:-10]) / ampf)
## Smooth it
mod.gmst <- loess(gmst ~ year, data=df.temp)
df.temp$smooth <- predict(mod.gmst)

library(dplyr)
library(MASS)

df <- df.temp %>% left_join(df.co2)
df$co2.delay <- c(NA, df$co2[-nrow(df)])
df$co2.unc.delay <- c(NA, df$co2.unc[-nrow(df)])
df$gmst.delay <- c(NA, df$gmst[-nrow(df)])
df$smooth.delay <- c(NA, df$smooth[-nrow(df)])
for (region in names(df)[1:8])
    df[, paste0(region, ".delay")] <- c(NA, df[-nrow(df), region])

## Show several models
mod.var.yr <- lm(gmst ~ year, data=df)
mod.var.co2 <- lm(gmst ~ co2, data=df)
mod.var.smooth <- lm(gmst ~ smooth, data=df)
mod.ar.co2 <- lm(gmst ~ gmst.delay + co2, data=df)
mod.ar.smooth <- lm(gmst ~ gmst.delay + smooth, data=df)

library(stargazer)
stargazer(list(mod.var.yr, mod.var.co2, mod.var.smooth, mod.ar.co2, mod.ar.smooth))

## Display realizations

projs <- data.frame()
for (mc in 1:10) {
    gmsts <- df$gmst[1]
    seres <- summary(mod.ar.smooth)$sigma
    for (ii in 2:nrow(df))
        gmsts <- c(gmsts, predict(mod.ar.smooth, data.frame(gmst.delay=gmsts[ii-1], smooth=df$smooth[ii])) + rnorm(1, 0, seres))

    projs <- rbind(projs, data.frame(mc, year=df$year, gmst=gmsts))
}

library(ggplot2)

ggplot(projs, aes(year, gmst)) +
    geom_line(data=subset(projs, mc != 1), aes(group=mc, colour="Other simulations"), size=.2) +
    geom_line(data=subset(projs, mc == 1), aes(group=mc, colour="One simulation")) +
    geom_line(data=df, aes(y=smooth, colour="Loess of GMST")) +
    geom_line(data=df, aes(colour="True GMST")) +
    scale_colour_manual(name=NULL, breaks=c('Loess of GMST', 'One simulation', 'Other simulations', 'True GMST'), values=c('#000000', '#1b9e77', '#9a9a9a', '#7570b3')) +
theme_bw() + scale_x_continuous(expand=c(0, 0)) + ylab("Change in GMST from pre-industrial") + xlab(NULL)
