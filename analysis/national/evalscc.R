setwd("~/research/iamup2/MimiPAGE2020.jl")

library(dplyr)
library(ggplot2)
library(reshape2)

df1 <- read.csv("output/allscc.csv")
df2 <- read.csv("output/allscc-2050.csv")
df3 <- read.csv("output/allscc-2100.csv")
baseline <- read.csv("data/bycountry.csv")

get.result.row <- function(df) {
    df2 <- df %>% filter(country == 'global')
    df3 <- df %>% filter(country != 'global') %>% group_by(country) %>% summarize(scc=mean(scc)) %>%
        left_join(baseline, by=c('country'='ISO3'))

    ## plot(density(df3$scc / df3$Pop2015))
    ## mean(df3$scc / df3$Pop2015) / sd(df3$scc / df3$Pop2015)
    ## plot(density(df3$scc / df3$GDP2015))
    ## mean(df3$scc / df3$GDP2015) / sd(df3$scc / df3$GDP2015)

    df3$GDPpc2015 <- df3$GDP2015 / df3$Pop2015

    mod <- lm(log(scc) ~ log(Pop2015) + log(GDPpc2015), data=df3)
    ## summary(mod) # R2 = 0.9737

    df3$expresid <- exp(mod$resid)
    mod2 <- lm(expresid ~ Temp2010, data=df3)
    ## summary(mod2)

    ## Model:
    ## SCC = (alpha0 + alpha1 T) (Pop^beta) (GDPpc^gamma)

    soln <- optim(c(1, mod2$coeff[2], mod$coeff[-1]), function(par) {
        scchat <- exp(mod$coeff[1]) * (par[1] + par[2] * df3$Temp2010) * df3$Pop2015^par[3] * df3$GDPpc2015^par[4] * exp(var(mod$resid) / 2)
        sccobs <- df3$scc
        sccprd <- scchat
        sccobs[scchat > 0] <- log(sccobs[sccprd > 0])
        sccprd[scchat > 0] <- log(scchat[scchat > 0])
        sum((sccobs - sccprd)^2)
    }, hessian=T)

    par <- soln$par
    df3$scchat <- exp(mod$coeff[1]) * (par[1] + par[2] * df3$Temp2010) * df3$Pop2015^par[3] * df3$GDPpc2015^par[4] * exp(var(mod$resid) / 2)

    rsqr <- summary(lm(log(scc) ~ 0 + log(scchat), data=df3))$r.squared

    vcv <- solve(soln$hessian)
    stderr <- sqrt(diag(vcv))

    data.frame(median=median(df2$scc), mean=mean(df2$scc), stddev=sd(df2$scc), alpha1=par[2], alpha1.se=stderr[2],
               beta=par[3], beta.se=stderr[3], gamma=par[4], gamma.se=stderr[4], rsqr)
}

pdf1 <- rbind(cbind(subset(df1, country == 'global'), group='2020'),
              cbind(subset(df2, country == 'global'), group='2050'),
              cbind(subset(df3, country == 'global'), group='2100')) %>%
    group_by(group) %>% summarize(mu=mean(scc), p025=quantile(scc, 0.025), p05=quantile(scc, 0.05),
                                  p25=quantile(scc, 0.25), p50=quantile(scc, 0.5),
                                  p75=quantile(scc, 0.75), p95=quantile(scc, 0.95), p975=quantile(scc, 0.975))
ggplot(pdf1, aes(group)) +
    coord_flip() +
    geom_boxplot(aes(min=p05, lower=p25, middle=p50, upper=p75, max=p95), stat="identity") +
    geom_point(aes(y=mu)) +
    geom_segment(aes(xend=group, y=p025, yend=p05), lty=2, lwd=0.4) +
    geom_segment(aes(xend=group, y=p975, yend=p95), lty=2, lwd=0.4) +
    theme_bw()

pdf2 <- rbind(cbind(get.result.row(df1), group='2020'),
              cbind(get.result.row(df2), group='2050'),
              cbind(get.result.row(df3), group='2100'))
pdf2.long <- cbind(melt(pdf2[, c('group', 'alpha1', 'beta', 'gamma')], id='group'),
                   se=melt(pdf2[, c('group', 'alpha1.se', 'beta.se', 'gamma.se')], id='group')$value)

ggplot(pdf2.long, aes(group)) +
    facet_wrap(~ variable, ncol=3, scales='free_x') +
    coord_flip() +
    geom_errorbar(aes(ymin=value - se, ymax=value + se)) +
    geom_point(aes(y=value)) +
    geom_hline(data=data.frame(variable=c('alpha1', 'beta', 'gamma'), value=c(0, 1, 1)), aes(yintercept=value), linetype='dashed') +
    theme_bw()
