setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/downscaling")

gmst <- read.csv("gmst-annual.csv")

bycountry <- data.frame()
for (gcm in unique(gmst$model)) {
    for (scn in unique(gmst$scenario)) {
        print(c(gcm, scn))
        filename <- paste0(gcm, '_', scn, '.csv')
        if (file.exists(filename)) {
            bgs <- read.csv(filename)
            bgs$year <- as.numeric(substring(bgs$time, 1, 4))
            bycountry <- rbind(bycountry, data.frame(year=bgs$year, model=gcm, scenario=scn, iso=bgs$adm0_a3, temp=bgs$var - 273.15))
        }
    }
}

library(dplyr)
df <- bycountry %>% left_join(gmst, by=c('year', 'model', 'scenario'))

library(lfe)
mod <- felm(temp ~ 0 + iso + iso : gsat, data=df)
coefs <- data.frame()
ccs <- coef(mod)
for (iso in unique(df$iso)) {
    coefs <- rbind(coefs, data.frame(ISO=iso, intercept=ccs[names(ccs) == paste0('iso', iso)],
                                     slope=ccs[names(ccs) == paste0('iso', iso, ':gsat')]))
}

write.csv(coefs, "../../data/climate/patterns_generic.csv", row.names=F)

coefs <- data.frame()
for (gcm in unique(df$model)) {
    print(gcm)
    mod <- felm(temp ~ 0 + iso + iso : gsat, data=subset(df, model == gcm))
    ccs <- coef(mod)
    for (iso in unique(df$iso)) {
        coefs <- rbind(coefs, data.frame(model=gcm, ISO=iso, intercept=ccs[names(ccs) == paste0('iso', iso)],
                                         slope=ccs[names(ccs) == paste0('iso', iso, ':gsat')]))
    }
}

write.csv(coefs, "../../data/climate/patterns.csv", row.names=F)
