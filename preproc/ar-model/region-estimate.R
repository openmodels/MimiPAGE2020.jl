# setwd("~/research/iamup/mimi-page-2020.jl/preproc/ar-model")

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
allmods <- list()
errors <- data.frame(year=1850:2018)
globmod <- NULL
for (region in c(names(df)[1:8], 'global')) {
    ##mod.ar <- lm(as.formula(paste0("`", region, "` ~ `", region, ".delay` + co2.delay")), data=df)
    ##mod.ar <- lm(as.formula(paste0("`", region, "` ~ `", region, ".delay` + smooth.delay")), data=df)
    if (region == 'global') {
        mod.ar <- lm(gmst ~ gmst.delay + smooth, data=df)
        globmod <- mod.ar
    } else {
        df$my.delay <- df[, paste0(region, '.delay')]
        mod.ar <- lm(as.formula(paste0("`", region, "` ~ my.delay + gmst")), data=df)
        allmods[[region]] <- mod.ar
    }

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

    errors[-1, region] <- mod.ar$residuals
}

write.csv(results, "arestimates.csv", row.names=F)

library(stargazer)

stargazer(globmod)
stargazer(allmods)

## How much correlation is there between error terms?

library(reshape2)

cormat <- round(cor(errors, use="complete"), 2)

cormat2 <- cormat
cormat2[lower.tri(cormat)] <- NA
cormat3 <- melt(cormat2)

allcor <- cbind(cormat3, model="Full AR Model")

cormat2x <- cormat2
diag(cormat2x) <- NA
cstats <- data.frame(model="Full AR Model", medvar=median(results$varerror),
                     medcor=median(abs(cormat2x), na.rm=T))

## Original correlation
varerrors <- sapply(c(names(df)[1:8], 'gmst'), function(reg) var(df[, reg]))
cormat <- round(cor(df[, c('year', names(df)[1:8], 'gmst')], use="complete"), 2)
rownames(cormat)[10] <- "global"
colnames(cormat)[10] <- "global"

cormat2 <- cormat
cormat2[lower.tri(cormat)] <- NA
cormat3 <- melt(cormat2)

allcor <- rbind(allcor, cbind(cormat3, model="Raw Temperatures"))
cormat2x <- cormat2
diag(cormat2x) <- NA
cstats <- rbind(cstats,
                data.frame(model="Raw Temperatures", medvar=median(varerrors),
                           medcor=median(abs(cormat2x), na.rm=T)))

## After remove smooth
varerrors2 <- c()
errors2 <- data.frame(year=1850:2018)
for (region in c(names(df)[1:8], 'global')) {
    if (region == 'global') {
        mod.ar <- lm(gmst ~ smooth, data=df)
    } else {
        mod.ar <- lm(as.formula(paste0("`", region, "` ~ smooth")), data=df)
    }

    errors2[, region] <- mod.ar$residuals
    varerrors2 <- c(varerrors2, var(mod.ar$residuals))
}

cormat <- round(cor(errors2, use="complete"), 2)

cormat2 <- cormat
cormat2[lower.tri(cormat)] <- NA
cormat3 <- melt(cormat2)

allcor <- rbind(allcor, cbind(cormat3, model="LOESS-only Model"))
cormat2x <- cormat2
diag(cormat2x) <- NA
cstats <- rbind(cstats,
                data.frame(model="LOESS-only Model", medvar=median(varerrors2),
                           medcor=median(abs(cormat2x), na.rm=T)))

## After remove AR
varerrors2 <- c()
errors2 <- data.frame(year=1851:2018)
for (region in c(names(df)[1:8], 'global')) {
    if (region == 'global') {
        mod.ar <- lm(gmst ~ gmst.delay, data=df)
    } else {
        df$my.delay <- df[, paste0(region, '.delay')]
        mod.ar <- lm(as.formula(paste0("`", region, "` ~ my.delay")), data=df)
    }

    errors2[, region] <- mod.ar$residuals
    varerrors2 <- c(varerrors2, var(mod.ar$residuals))
}

cormat <- round(cor(errors2, use="complete"), 2)

cormat2 <- cormat
cormat2[lower.tri(cormat)] <- NA
cormat3 <- melt(cormat2)

allcor <- rbind(allcor, cbind(cormat3, model="AR-only Model"))
cormat2x <- cormat2
diag(cormat2x) <- NA
cstats <- rbind(cstats,
                data.frame(model="AR-only Model", medvar=median(varerrors2),
                           medcor=median(abs(cormat2x), na.rm=T)))

allcor$model <- factor(allcor$model, levels=c('Raw Temperatures', 'LOESS-only Model', "AR-only Model", 'Full AR Model'))
cstats$model <- factor(cstats$model, levels=c('Raw Temperatures', 'LOESS-only Model', "AR-only Model", 'Full AR Model'))

allcor$Var1 <- factor(allcor$Var1)
allcor$Var2 <- factor(allcor$Var2, levels=rev(levels(allcor$Var1)))

library(ggplot2)
ggplot(data=allcor) +
    facet_wrap(~ model) +
    geom_tile(aes(x=Var1, y=Var2, fill=value), color = "white")+
    geom_label(data=cstats, aes(label="Medians:"), y=9.6, x=7) +
    geom_label(data=cstats, aes(label=paste0("Var(e) = ", round(medvar, 2))), y=8.3, x=7) +
    geom_label(data=cstats, aes(label=paste0("|cor| = ", round(medcor, 2))), y=7, x=7) +
    scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                         midpoint = 0, limit = c(-1,1), space = "Lab",
                         name="Pearson\nCorrelation") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, vjust = 1,
                                     size = 9, hjust = 1))+
    coord_fixed() + xlab(NULL) + ylab(NULL)

