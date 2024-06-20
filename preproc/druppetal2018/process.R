setwd("~/research/iamup2/MimiPAGE2020.jl")

library(readstata13)
df = read.dta13("preproc/druppetal2018/Drupp_et_al_2018.dta")

df2 <- df[!is.na(df$puretp) & !is.na(df$eta), c('puretp', 'eta')]

## pdf <- expand.grid(prtp=unique(df2$puretp), emuc=unique(df2$eta))
library(dplyr)
df3 <- df2 %>% group_by(puretp, eta) %>% summarize(count=length(eta))
df3$puretp <- factor(df3$puretp)
df3$eta <- factor(df3$eta)

library(ggplot2)
ggplot(df3, aes(puretp, eta, fill=count)) +
    geom_tile()

df2$prtp.round <- round(2 * df2$puretp) / 2
df2$emuc.round <- round(2 * df2$eta) / 2

df3 <- df2 %>% group_by(prtp.round, emuc.round) %>% summarize(count=length(eta))
ggplot(df3, aes(prtp.round, emuc.round, fill=count)) +
    geom_tile() + scale_x_continuous("Pure rate of time preference", expand=c(0, 0)) +
    scale_y_continuous("Elasticity of marginal utility", expand=c(0, 0))

df2$prtp.round <- round(df2$puretp)
df2$emuc.round <- round(df2$eta)

df3 <- df2 %>% group_by(prtp.round, emuc.round) %>% summarize(count=length(eta))

ggplot(df3, aes(prtp.round, emuc.round, fill=count)) +
    geom_tile() + scale_x_continuous("Pure rate of time preference", expand=c(0, 0)) +
    scale_y_continuous("Elasticity of marginal utility", expand=c(0, 0))


write.csv(df2, "data/preferences/druppetal2018.csv", row.names=F)
