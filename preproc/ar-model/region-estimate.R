setwd("~/research/iamup/persistence")

df.co2 <- read.csv("co2conc.csv")
df.temp <- as.data.frame(t(as.matrix(read.csv("region-temps.csv", header=F))))
colnames(df.temp) <- c('eu', 'rus+', 'usa', 'chi+', 'ind+', 'afr', 'lat', 'oth')
df.temp$year <- 1850:2018

library(dplyr)
library(MASS)

df <- df.temp %>% left_join(df.co2, by=c('year'='years'))
df$co2.delay <- c(NA, df$rcp45[-nrow(df)])
for (region in names(df)[1:8])
    df[, paste0(region, ".delay")] <- c(NA, df[-nrow(df), region])

results <- data.frame()
for (region in names(df)[1:8]) {
    mod.ar <- lm(as.formula(paste0("`", region, "` ~ `", region, ".delay` + co2.delay")), data=df)

    errsigma <- summary(mod.ar)$sigma
    coeffs <- mod.ar$coefficients
    vcv <- vcov(mod.ar)

    terms <- c('intercept', 'ar', 'co2')
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
