setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/burkey")

library(readxl)
library(reshape2)
library(dplyr)
library(ggplot2)
library(rstan)

choose.heathelp <- 'drop'
choose.heatonly <- T
choose.index <- 'INFORM'

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

df <- read.csv("ExtendedDataFig1g.csv")

gamma <- c(0.0127183, -0.0004871)
gammavcv <- matrix(c(0.0000143,-0.000000376,-3.76E-07,1.40E-08), 2, 2, byrow=T)

## Marginal effect: beta1 + 2 beta2 T
df$fit2 <- gamma[1] + 2 * gamma[2] * df$meantemp
df$fitse <- sapply(df$meantemp, function(TT) sqrt(t(c(1, 2*TT)) %*% gammavcv %*% t(t(c(1, 2*TT)))))

ggplot(df, aes(meantemp)) +
    geom_line(aes(y=fit, colour=fit < 0)) +
    geom_ribbon(aes(ymin=fit - 1.96 * fitse, ymax=fit + 1.96 * fitse), alpha=.25) +
    geom_point(aes(y=b, colour=b < 0)) +
    scale_x_continuous("Population-weighted average temperature (C)", expand=c(0, 0)) + ylab("Marginal effect of warming") +
    scale_colour_manual("Marginal sign", breaks=c(T, F), labels=c("Negative", "Positive"), values=c("#d95f02", "#7570b3")) +
    theme_bw()
ggsave("deviations.pdf", width=6.5, height=4)

if (choose.heathelp == 'allow') {
    valid <- T
    df$delta <- df$b - df$fit
} else if (choose.heathelp == 'clip') {
    df$bclip <- df$b
    df$bclip[df$b > 0] <- 0
    valid <- df$fit < 0
    df$delta <- df$bclip - df$fit
} else { # 'drop'
    valid <- df$b < 0
    df$delta <- df$b - df$fit
}

if (choose.heatonly) {
    opttemp <- -gamma[1] / (2 * gamma[2])
    valid <- valid & (df$meantemp > opttemp)
}

df$deltase <- sqrt(df$se^2 + df$fitse^2)

## Look for best fitting year
r2s <- data.frame()

burkedf <- read.csv("GrowthClimateDataset.csv")
for (year in 2000:2011) {
    burkedf.year <- burkedf[burkedf$year == year, c('iso', 'gdpCAPppp')]

    df2 <- df %>% left_join(burkedf.year, by='iso')
    mod <- lm(delta ~ log(gdpCAPppp), weights=1 / df2$deltase[valid]^2, data=df2[valid,])

    r2s <- rbind(r2s, data.frame(source='Income', year, theory=mod$coeff[2] > 0, r2=summary(mod)$r.squared))
}

for (year in 2000:2022) {
    wri <- read_xlsx("WRI_FullData_Time-series-2000-2022.xlsx", sheet=year - 2000 + 2)
    wri <- wri[, 2:8]

    df2 <- df %>% left_join(wri, by=c('iso'='Code'))
    mod <- lm(delta ~ log(W), weights=1 / df2$deltase[valid]^2, data=df2[valid,])

    r2s <- rbind(r2s, data.frame(source='WRI', year, theory=mod$coeff[2] < 0, r2=summary(mod)$r.squared))
}

icc <- read_xlsx("INFORM2022_TREND_2013_2022_v063_ALL.xlsx")
icc <- subset(icc, IndicatorName %in% c('INFORM Risk Index', 'Hazard & Exposure Index', 'Vulnerability Index', 'Lack of Coping Capacity Index'))

for (year in unique(icc$INFORMYear)) {
    iccy <- dcast(subset(icc, INFORMYear == year), Iso3 ~ IndicatorId, value.var='IndicatorScore')

    df2 <- df %>% left_join(iccy, by=c('iso'='Iso3'))
    mod <- lm(delta ~ log(INFORM), weights=1 / df2$deltase[valid]^2, data=df2[valid,])

    r2s <- rbind(r2s, data.frame(source='INFORM', year, theory=mod$coeff[2] < 0, r2=summary(mod)$r.squared))
}

ggplot(r2s, aes(year, r2, colour=source, alpha=theory)) +
    geom_point() + theme_bw() +
    scale_colour_discrete("Covariate") +
    scale_alpha_manual("Matches theory", breaks=c(F, T), labels=c("No", "Yes"), values=c(0.4, 1)) +
    xlab("Year of covariate") + ylab("Coefficient of determination")
ggsave("covarcompare.pdf", width=6.5, height=4)

## 2006
wri <- read_xlsx("WRI_FullData_Time-series-2000-2022.xlsx", sheet=2006 - 2000 + 2)
wri <- wri[, 2:8]

## 2014
icc <- read_xlsx("INFORM2022_TREND_2013_2022_v063_ALL.xlsx")
icc <- subset(icc, IndicatorName %in% c('INFORM Risk Index', 'Hazard & Exposure Index', 'Vulnerability Index', 'Lack of Coping Capacity Index'))
icc <- dcast(subset(icc, INFORMYear == 2014), Iso3 ~ IndicatorId, value.var='IndicatorScore')

## Collect GDPpc
burkedf.2011 <- burkedf[burkedf$year == 2011, c('iso', 'gdpCAPppp')]

df2 <- df %>% left_join(wri, by=c('iso'='Code')) %>% left_join(icc, by=c('iso'='Iso3')) %>% left_join(burkedf.2011, by='iso')

ggplot(df2, aes(gdpCAPppp, delta, alpha=valid)) +
    geom_point() + geom_linerange(aes(ymin=delta-deltase, ymax=delta+deltase)) +
    geom_smooth(method='lm', se=T) +
    scale_x_log10()

summary(lm(delta ~ log(gdpCAPppp), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))

ggplot(df2, aes(W, delta, alpha=valid)) +
    geom_point() + geom_linerange(aes(ymin=delta-deltase, ymax=delta+deltase)) +
    scale_x_log10()

summary(lm(delta ~ log(W), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))
summary(lm(delta ~ log(E) + log(S) + log(C) + log(A), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))
summary(lm(delta ~ log(E) + log(S) + log(C) + log(A) + log(gdpCAPppp), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))

ggplot(df2, aes(INFORM, delta, alpha=valid)) +
    geom_point() + geom_linerange(aes(ymin=delta-deltase, ymax=delta+deltase)) +
    scale_x_log10() + theme_bw() + xlab("INFORM Risk Index") + ylab("Deviation from expectation")

summary(lm(delta ~ log(INFORM), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))
summary(lm(delta ~ log(HA) + log(VU) + log(CC), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))
summary(lm(delta ~ log(HA) + log(VU) + log(CC) + log(gdpCAPppp), weights=1 / df2$deltase[valid]^2, data=df2[valid,]))

stan.code <- "
data {
  int<lower=0> N; // countries
  int<lower=0> K; // indicators

  vector[N] delta;
  vector[N] se;

  vector[K] xx[N];
  vector[N] loggdppc;
}
parameters {
  real alpha;
  vector<upper=0>[K] beta;
  real<lower=0> gamma;
  real<lower=0> sigma;
}
model {
  for(ii in 1:N) {
    target += normal_lpdf(delta[ii] | alpha + dot_product(xx[ii], beta) + gamma * loggdppc[ii], sigma) / se[ii]^2;
  }
}"

if (choose.index == 'INFORM') {
    valid2 <- valid & rowSums(is.na(df2[, c('delta', 'HA', 'VU', 'CC', 'gdpCAPppp')])) == 0
    stan.data <- list(N=sum(valid2), K=3, delta=df2$delta[valid2], se=df2$deltase[valid2],
                      xx=log(df2[valid2, c('HA', 'VU', 'CC')]), loggdppc=log(df2$gdpCAPppp[valid2]))
} else {
    valid2 <- valid & rowSums(is.na(df2[, c('delta', 'E', 'S', 'C', 'A', 'gdpCAPppp')])) == 0
    stan.data <- list(N=sum(valid2), K=4, delta=df2$delta[valid2], se=df2$deltase[valid2],
                      xx=log(df2[valid2, c('E', 'S', 'C', 'A')]), loggdppc=log(df2$gdpCAPppp[valid2]))
}

fit <- stan(model_code=stan.code, data=stan.data,
            iter = 2000, chains = 4)
la <- extract(fit, permute=T)

pdf <- melt(la$beta)
if (choose.index == 'INFORM') {
    pdf$label <- "Hazard & Exposure"
    pdf$label[pdf$Var2 == 2] <- "Vulnerability"
    pdf$label[pdf$Var2 == 3] <- "Lack of Coping Capacity"
} else {
    pdf$label <- "Exposure"
    pdf$label[pdf$Var2 == 2] <- "Susceptibility"
    pdf$label[pdf$Var2 == 3] <- "Lack of Coping Capacities"
    pdf$label[pdf$Var2 == 4] <- "Lack of Adaptive Capacities"
}
pdf <- rbind(pdf[, c('label', 'value')], data.frame(label="Intercept", value=la$alpha), data.frame(label="Log Income", value=la$gamma))
if (choose.index == 'INFORM') {
    pdf$label <- factor(pdf$label, levels=c("Intercept", "Hazard & Exposure", "Vulnerability", "Lack of Coping Capacity", "Log Income"))
} else {
    pdf$label <- factor(pdf$label, levels=c("Intercept", "Exposure", "Susceptibility", "Lack of Coping Capacities", "Lack of Adaptive Capacities", "Log Income"))
}

ggplot(pdf, aes(value)) +
    facet_wrap(~ label, scales='free', ncol=5) +
    geom_density() + theme_bw() + xlab("Hyper parameter value")
ggsave("hypers.pdf", width=12, height=4)

## Adjust intercept
bias <- sum(df2$delta[valid2] * 1 / df2$deltase[valid2]^2) / sum(1 / df2$deltase[valid2]^2)

rdf <- cbind(la$alpha - bias, as.data.frame(la$beta), la$gamma) # NOTE: intercept already is bias-corrected
if (choose.index == 'INFORM') {
    names(rdf) <- c('Intercept', 'HA', 'VU', 'CC', 'loggdppc')
} else {
    names(rdf) <- c('Intercept', 'Exposure', 'Susceptibility', 'CopingLack', 'AdaptiveLack', 'loggdppc')
}

write.csv(rdf, "burkey-estimates.csv", row.names=F)

if (choose.index == 'INFORM') {
    mod <- lm(delta ~ log(HA) + log(VU) + log(CC) + log(gdpCAPppp), weights=1 / df2$deltase[valid]^2, data=df2[valid,])
} else {
    mod <- lm(delta ~ log(E) + log(S) + log(C) + log(A) + log(gdpCAPppp), weights=1 / df2$deltase[valid]^2, data=df2[valid,])
}
summary(mod)
anova(mod)

df2$fit3.ols <- df2$fit + predict(mod, df2)
df2$delta3 <- NA
if (choose.index == 'INFORM') {
    df2$delta3[valid2] <- sapply(which(valid2), function(ii) mean(t(t(la$alpha)) + la$beta %*% t(log(df2[ii, c('HA', 'VU', 'CC')])) + t(t(la$gamma)) * log(df2$gdpCAPppp[ii])))
} else {
    df2$delta3[valid2] <- df2$fit[valid2] + sapply(which(valid2), function(ii) mean(t(t(la$alpha)) + la$beta %*% t(log(df2[ii, c('E', 'S', 'C', 'A')])) + t(t(la$gamma)) * log(df2$gdpCAPppp[ii])))
}
df2$fit3 <- df2$fit + df2$delta3
head(df2)


ggplot(df2, aes(meantemp)) +
    geom_point(aes(y=b, colour='Country OLS')) + geom_point(aes(y=fit, colour='Global OLS')) +
    geom_point(aes(y=fit3.ols - bias, colour='Hyper OLS')) + geom_point(aes(y=fit3 - bias, colour='Hyper Bayes')) +
    theme_bw() + xlab("Annual average temperature (C)") + ylab("Marginal effect of temperature")
ggsave("methodcomp.pdf", width=6.5, height=4)
