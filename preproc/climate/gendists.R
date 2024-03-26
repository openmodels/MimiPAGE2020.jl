## setwd("~/Dropbox/Country-Level PAGE/climate/patterns")

library(dplyr)

do.redo.gendists <- F
do.redo.faireocs <- F

gmst <- read.csv("gmst.csv")

gmst.base <- gmst[gmst$period == "1995-2015",]
gmst.2100 <- gmst[gmst$period == "2081-2100",]

gmst2 <- gmst.2100 %>% left_join(gmst.base, by='model', suffix=c('', '.base'))
gmst2$warming <- gmst2$gsat - gmst2$gsat.base + 0.85

if (do.redo.gendists) {
    library(raster)
    library(abind)

    results <- data.frame()
    for (scenario in c('ssp126', 'ssp370')) {
        options <- gmst2[gmst2$scenario == scenario,]

        ## 1. Calculate average correlation between GCM temperature and anomalies, across grid-cells
        allvals <- NULL
        draws <- matrix(NA, 1e5, nrow(options))
        for (ii in 1:nrow(options)) {
            system(paste0("unzip \"", file.path(path.expand(datapath), paste0("../worldclim/future/wc2.1_10m_bioc_", options$model[ii], "_", scenario, "_2081-2100.zip")), "\" -d ~/tmp"))
            for (tiffile in list.files("~/tmp/share", recursive=T)) {
                rr <- raster(paste0("~/tmp/share/", tiffile), band=1)
            }
            dd <- as.matrix(rr)
            system("rm -r ~/tmp/share")

            if (is.null(allvals))
                allvals <- dd
            else
                allvals <- abind(allvals, dd, along=3)
            draws[, ii] <- rnorm(1e5)
        }
        cors <- apply(allvals, 1:2, function(vv) cor(options$warming, vv - options$gsat.base))
        weights <- as.matrix(area(rr))
        target <- weighted.mean(abs(cors), weights, na.rm=T)

        ## Now use draws to do optimization
        res <- optimize(function(tau) {
            gcors <- sapply(1:1e5, function(ii) cor(options$warming, draws[ii,] * tau + options$warming))
        (target - mean(gcors))^2
        }, c(0, 1))

        results <- rbind(results, data.frame(scenario, tau=res$minimum))
    }

    write.csv(results, "gendists.csv", row.names=F)
}

if (do.redo.faireocs) {
    alldraws <- read.csv("ssps_26_70_ukproject_allmembers.csv")

    ## Get all EOC temperatures
    eocs <- data.frame()
    for (run_id in unique(alldraws$run_id)) {
        for (scenario in c('ssp126', 'ssp370')) {
            draw <- alldraws[alldraws$scenario == scenario & alldraws$run_id == run_id,]
            warming.base <- mean(draw$value[draw$year >= 1995 & draw$year < 2015])
            warming.eoc <- mean(draw$value[draw$year >= 2081 & draw$year < 2100])

            eocs <- rbind(eocs, data.frame(run_id, scenario, warming=warming.eoc - warming.base + 0.85))
        }
    }

    library(reshape2)
    eocs2 <- dcast(eocs, run_id ~ scenario)

    ## Order it across both scenarios
    eocs.ordered <- eocs2[order(eocs2$ssp126 + eocs2$ssp370),]

    ## plot(eocs.ordered$ssp126, eocs.ordered$ssp370)

    write.csv(eocs.ordered, "warmeocs.csv", row.names=F)
    write.csv(gmst2, "gmsts.csv", row.names=F)
}

eocs.ordered <- read.csv("warmeocs.csv")
fit.gendists <- read.csv("gendists.csv")

get.pattern <- function(prcile) {
    row <- round(prcile * (nrow(eocs.ordered) - .01) + .505)

    pattern1 <- 1
    pattern2 <- 2

    while (pattern1 != pattern2) {
        probs <- dnorm(eocs.ordered$ssp126[row], gmst2$warming[gmst2$scenario == 'ssp126'], fit.gendists$tau[fit.gendists$scenario == 'ssp126'])
        pattern <- sample(1:length(probs), 1, prob=probs)

        pattern1 <- gmst2$model[pattern]

        probs <- dnorm(eocs.ordered$ssp370[row], gmst2$warming[gmst2$scenario == 'ssp370'], fit.gendists$tau[fit.gendists$scenario == 'ssp370'])
        pattern <- sample(1:length(probs), 1, prob=probs)

        pattern2 <- gmst2$model[pattern]
    }

    return(pattern1)
}
