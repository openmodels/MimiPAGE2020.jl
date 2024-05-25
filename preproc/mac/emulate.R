setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/mac/")

library(readxl)
library(reshape2)
library(dplyr)
library(ggplot2)
library(splines)
library(nnls)

df <- read_excel("1665743477883-V3.4-NGFS-Phase-3/Downscaled_data.xlsx")

## Get baseline emissions in 2015
baseline <- df %>% filter(Variable %in% c("Emissions|CO2|Energy", "Emissions|CO2|Industrial Processes")) %>%
    group_by(Model, Scenario, Region) %>% summarize(count=length(`2015`), co2=sum(`2015`)) %>%
    group_by(Region) %>% summarize(co2mu=mean(co2), co2sd=sd(co2))
write.csv(baseline, "../../data/e0_baselineCO2emissions_country.csv", row.names=F)

quantile(df[df$Variable == "Price|Carbon", -1:-5], na.rm=T) # 0, so no negative prices
df$`2010`[df$Variable == "Price|Carbon"]

df2 <- subset(df, Region == "USA" &
                  Variable %in% c("Carbon Sequestration|CCS", "Emissions|CO2|Energy",
                                  "Emissions|CO2|Industrial Processes", "Price|Carbon",
                                  "GDP|PPP|Counterfactual without damage"))
df3 <- melt(df2, names(df)[1:5], variable.name='Year')

df4 <- subset(df3, Variable == "Carbon Sequestration|CCS") %>%
    left_join(subset(df3, Variable == "Emissions|CO2|Energy"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('', '.eco2')) %>%
    left_join(subset(df3, Variable == "Emissions|CO2|Industrial Processes"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('', '.ico2')) %>%
    left_join(subset(df3, Variable == "GDP|PPP|Counterfactual without damage"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('', '.gdp')) %>%
    left_join(subset(df3, Variable == "Price|Carbon"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('.ccs', '.carbonprice'))
df4$value.co2 <- df4$value.eco2 + df4$value.ico2 # Don't include CCS-- assume it's in reduced CO2 (since I see negative values there)
df4$value.loggdp <- log(df4$value.gdp)

if (F) {
    ggplot(df4, aes(value.carbonprice, value.co2)) +
        geom_point(aes(colour=Scenario))

    ggplot(df4, aes(value.carbonprice, value.loggdp)) +
        geom_point(aes(colour=Scenario))
}

df4$Year <- as.numeric(as.character(df4$Year))
if (F) {
    summary(lm(value.co2 ~ value.carbonprice + lag(value.co2) + Year, data=df4))
    summary(lm(value.loggdp ~ value.carbonprice + lag(value.loggdp) + Year, data=df4))
}

## Okay, but what if I want a time-varying MAC?
## This will give the total abatement costs
df5 <- df4 %>% group_by(Model, Scenario) %>% mutate(lag.value.co2=lag(value.co2), lag.value.loggdp=lag(value.loggdp))

if (F) {
    summary(lm(value.co2 ~ value.carbonprice + lag.value.co2 + Year, data=df5))
    summary(lm(value.co2 ~ value.carbonprice + lag.value.co2 + Year + Scenario, data=df5))
    summary(lm(value.co2 ~ value.carbonprice + lag.value.co2 + factor(Year) + Scenario, data=df5))

    summary(lm(value.co2 ~ ns(value.carbonprice, knots=c(20, 50, 100, 200, 500, 1000)) * Year + lag.value.co2, data=df5))

    mod <- lm(value.co2 ~ ns(value.carbonprice, knots=c(20, 50, 100, 200, 500, 1000)) * Year + lag.value.co2, data=df5)
    pdf <- expand.grid(value.carbonprice=seq(0, max(df4$value.carbonprice, na.rm=T)),
                       Year=c(2020, 2050),
                       `lag.value.co2`=max(df4$value.co2, na.rm=T)) #, max(df4$value.co2, na.rm=T)/2))
    pdf$value.co2.next <- predict(mod, pdf)

    ggplot(pdf, aes(value.carbonprice, value.co2.next, group=paste(Year, lag.value.co2))) +
        geom_line(aes(colour=factor(Year), linetype=factor(lag.value.co2))) +
        coord_cartesian(ylim=c(0, max(df4$value.co2, na.rm=T)))

    pdf <- df5 %>% group_by(Year) %>% summarize(value.carbonprice=mean(value.carbonprice), lag.value.co2=mean(lag.value.co2))
    pdf$value.co2.next <- predict(mod, pdf)

    ggplot(subset(pdf, Year >= 2015), aes(value.carbonprice, value.co2.next)) +
        geom_line() +
        coord_cartesian(ylim=c(0, max(df4$value.co2, na.rm=T)))
}

make.AA <- function(df5, df5.modscens, lag.col='lag.value.co2', swapyear=F) {
    ## Enforce MAC-ness by having each segment be 0000.1.2.3...11111
    df5$ac.0.20 <- pmin(df5$value.carbonprice / 20, 1)
    df5$ac.20.50 <- pmin(pmax(0, (df5$value.carbonprice - 20) / 30), 1)
    df5$ac.50.100 <- pmin(pmax(0, (df5$value.carbonprice - 50) / 50), 1)
    df5$ac.100.200 <- pmin(pmax(0, (df5$value.carbonprice - 100) / 100), 1)
    df5$ac.200.500 <- pmin(pmax(0, (df5$value.carbonprice - 200) / 300), 1)
    df5$ac.500.inf <- pmax(0, (df5$value.carbonprice - 500) / 500)

    if (swapyear) {
        yeardiff <- 2050 - df5$Year
    } else {
        yeardiff <- df5$Year - 2000
    }
    df5$ac.0.20.year <- df5$ac.0.20 * yeardiff
    df5$ac.20.50.year <- df5$ac.20.50 * yeardiff
    df5$ac.50.100.year <- df5$ac.50.100 * yeardiff
    df5$ac.100.200.year <- df5$ac.100.200 * yeardiff
    df5$ac.200.500.year <- df5$ac.200.500 * yeardiff
    df5$ac.500.inf.year <- df5$ac.500.inf * yeardiff

    AA <- df5[, c('ac.0.20', 'ac.20.50', 'ac.50.100', 'ac.100.200', 'ac.200.500', 'ac.500.inf',
                  'ac.0.20.year', 'ac.20.50.year', 'ac.50.100.year', 'ac.100.200.year', 'ac.200.500.year', 'ac.500.inf.year',
                  lag.col)]
    AA <- as.matrix(AA)
    for (year in unique(df5.modscens$Year[!is.na(df5.modscens$value.carbonprice)])) {
        AA <- cbind(AA, df5$Year == year)
    }
    modscens <- unique(df5.modscens[!is.na(df5.modscens$value.carbonprice), c('Model', 'Scenario')])
    for (msii in 1:nrow(modscens)) {
        AA <- cbind(AA, df5$Model == modscens$Model[msii] & df5$Scenario == modscens$Scenario[msii])
    }
    AA
}

AA <- make.AA(df5, df5)
valid <- !is.na(rowSums(AA))
mod <- nnnpls(AA[valid,], df5$value.co2[valid], c(rep(-1, 6), rep(-1, 6), 1, rep(1, ncol(AA) - 13)))

AA <- make.AA(df5, df5, lag.col='lag.value.loggdp', swapyear=T)
mod <- nnnpls(AA[valid,], df5$value.loggdp[valid], c(rep(-1, 6), rep(-1, 6), 1, rep(1, ncol(AA) - 13)))

## allfits <- NULL
allfits <- data.frame()
allpdf <- data.frame()
for (iso in unique(df$Region)) {
    print(iso)
    df2 <- subset(df, Region == iso &
                      Variable %in% c("Emissions|CO2|Energy",
                                      "Emissions|CO2|Industrial Processes", "Price|Carbon",
                                      "GDP|PPP|Counterfactual without damage"))
    df3 <- melt(df2, names(df)[1:5], variable.name='Year')

    df4 <- subset(df3, Variable == "Emissions|CO2|Energy") %>%
        left_join(subset(df3, Variable == "Emissions|CO2|Industrial Processes"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('', '.ico2')) %>%
        left_join(subset(df3, Variable == "GDP|PPP|Counterfactual without damage"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('', '.gdp')) %>%
        left_join(subset(df3, Variable == "Price|Carbon"), by=c('Model', 'Scenario', 'Region', 'Year'), suffix=c('.eco2', '.carbonprice'))
    df4$value.co2 <- df4$value.eco2 + df4$value.ico2
    df4$value.loggdp <- log(df4$value.gdp)
    df4$Year <- as.numeric(as.character(df4$Year))

    df5 <- df4 %>% group_by(Model, Scenario) %>% mutate(lag.value.co2=lag(value.co2), lag.value.loggdp=lag(value.loggdp))

    AA.co2 <- make.AA(df5, df5)
    AA.gdp <- make.AA(df5, df5, lag.col='lag.value.loggdp', swapyear=T)
    valid <- !is.na(rowSums(AA.co2))
    for (bs in 1:100) {
        bootstrap <- sample(which(valid), sum(valid), replace=T)
        AA.co2bs <- AA.co2[bootstrap,]
        AA.gdpbs <- AA.gdp[bootstrap,]

        mod.co2 <- nnnpls(AA.co2bs, df5$value.co2[bootstrap], c(rep(-1, 6), rep(-1, 6), 1, rep(1, ncol(AA.co2bs) - 13)))
        mod.gdp <- nnnpls(AA.gdpbs, df5$value.loggdp[bootstrap], c(rep(-1, 6), rep(-1, 6), 1, rep(1, ncol(AA.gdpbs) - 13)))

        baseline <- df5$lag.value.co2[df5$Year == 2015 & df5$Model == 'Downscaling [MESSAGEix-GLOBIOM 1.1-M-R12]' & df5$Scenario == 'Current Policies']
        pdf <- data.frame(Year=2030, value.carbonprice=c(0, 20, 50, 100, 200, 500, 1000), lag.value.co2=0)
        AA.co2pdf <- make.AA(cbind(pdf, Model='Downscaling [MESSAGEix-GLOBIOM 1.1-M-R12]', Scenario='Current Policies'), df5)
        AA.co2pdf[, 14:ncol(AA.co2pdf)] <- 0
        pdf$value.co2.next <- as.numeric(AA.co2pdf %*% mod.co2$x)
        pdf$abated <- -pdf$value.co2.next / baseline

        fits <- as.data.frame(t(c(mod.co2$x[1:13], mod.gdp$x[1:13])))
        names(fits) <- c('ac_0-20_co2', 'ac_20-50_co2', 'ac_50-100_co2', 'ac_100-200_co2', 'ac_200-500_co2', 'ac_500-inf_co2',
                         'ac_0-20xyear_co2', 'ac_20-50xyear_co2', 'ac_50-100xyear_co2', 'ac_100-200xyear_co2', 'ac_200-500xyear_co2', 'ac_500-infxyear_co2',
                         'lag_value_co2',
                         'ac_0-20_gdp', 'ac_20-50_gdp', 'ac_50-100_gdp', 'ac_100-200_gdp', 'ac_200-500_gdp', 'ac_500-inf_gdp',
                         'ac_0-20xyear_gdp', 'ac_20-50xyear_gdp', 'ac_50-100xyear_gdp', 'ac_100-200xyear_gdp', 'ac_200-500xyear_gdp', 'ac_500-infxyear_gdp',
                         'lag_value_gdp')
        allfits <- rbind(allfits, cbind(iso=iso, bs=bs, fits))

        ## fits <- as.data.frame(matrix(vcov(mod.co2), length(coef(mod.co2)), length(coef(mod.co2))))
        ## names(fits) <- names(coef(mod.co2))
        ## fits <- cbind(iso=iso, coef=coef(mod.co2), fits)
        ## if (is.null(fits)) {
        ##     allfits <- fits
        ## } else {
        ##     fits <- rbind(allfits, fits)
        ## }
        allpdf <- rbind(allpdf, cbind(iso=iso, bs=bs, pdf))
    }
}

allpdf$adjusted <- allpdf$abated / (exp(-allpdf$value.carbonprice / 500) + allpdf$abated)
allpdf2 <- allpdf %>% group_by(iso, value.carbonprice) %>% summarize(ci25=quantile(adjusted, .25), ci75=quantile(adjusted, .75), adjusted=mean(adjusted))

ggplot(allpdf2, aes(value.carbonprice, adjusted, group=iso)) +
    geom_line() + geom_ribbon(aes(ymin=ci25, ymax=ci75), alpha=.1) +
    coord_cartesian(ylim=c(0, 1)) + theme_bw() +
    scale_x_continuous("Carbon price (US$2010/t CO2)", expand=c(0, 0)) +
    scale_y_continuous("Total abatement (%)", expand=c(0, 0), labels=scales::percent)
ggsave("macs.pdf", width=6.5, height=5)

write.csv(allfits, "../../data/macs.csv", row.names=F)
write.csv(allpdf, "allpdf.csv", row.names=F)
