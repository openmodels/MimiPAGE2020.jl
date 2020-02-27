# setwd("~/research/mimi-page/mimi-page-2020.jl/preproc/ar-model")

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

results <- data.frame()
for (region in c(names(df)[1:8], 'global')) {
    ##mod.ar <- lm(as.formula(paste0("`", region, "` ~ `", region, ".delay` + co2.delay")), data=df)
    ##mod.ar <- lm(as.formula(paste0("`", region, "` ~ `", region, ".delay` + smooth.delay")), data=df)
    if (region == 'global')
        mod.ar <- lm(gmst ~ gmst.delay + smooth, data=df)
    else
        mod.ar <- lm(as.formula(paste0("`", region, "` ~ `", region, ".delay` + gmst")), data=df)

    errsigma <- summary(mod.ar)$sigma
    coeffs <- mod.ar$coefficients
    vcv <- vcov(mod.ar)

    ##terms <- c('intercept', 'ar', 'co2')
    terms <- c('intercept', 'ar', 'gmst')
    row <- data.frame(region)
    for (ii in 1:3)
        row[1, terms[ii]] <- coeffs[ii]
    for (ii in 1:3) {
        for (jj in 1:3)
            row[1, paste0('var', terms[ii], "*", terms[jj])] <- vcv[ii, jj]
    }
    row$varerror <- errsigma^2

    results <- rbind(results, row)
}

write.csv(results, "arestimates.csv", row.names=F)
