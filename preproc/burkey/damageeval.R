setwd("~/research/iamup2/MimiPAGE2020.jl")

## Currently all 0 because impmax = 0
impmax_maximumadaptivecapacitys <- read.csv("data/impmax_economic.csv", skip=2)$impmax_1_a
plateau_increaseintolerableplateaufromadaptations <- read.csv("data/plateau_increaseintolerableplateaufromadaptationM.csv", skip=2)$plateau_1_a
pstart_startdateofadaptpolicys <- read.csv("data/pstart_startdateofadaptpolicyM.csv", skip=2)$pstart_1_a
pyears_yearstilfulleffects <- read.csv("data/pyears_yearstilfulleffectM.csv", skip=2)$pyears_1_a
impred_eventualpercentreductions <- read.csv("data/impred_eventualpercentreductionM.csv", skip=2)$impred_1_a
istart_startdates <- read.csv("data/istart_startdateM.csv", skip=2)$istart_1_a
iyears_yearstilfulleffects <- read.csv("data/iyears_yearstilfulleffectM.csv", skip=2)$iyears_1_a
cf_costregionals <- read.csv("data/cf_costregional.csv", skip=2)$Adaptive.costs.factor
cp_costplateau_eu <- 0.0116666666666667
ci_costimpact_eu <- 0.0040000000

y_years <- c(2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300)
y_year_0 <- 2015
y_year_lssp <- 2100
automult_autonomoustechchange <- .65

calc.adaptcosts <- function(y_year, region, autofac_autonomoustechchangefraction,
                            pstart_startdateofadaptpolicy, pyears_yearstilfulleffect, plateau_increaseintolerableplateaufromadaptation,
                            istart_startdate, iyears_yearstilfulleffect, impred_eventualpercentreduction,
                            cf_costregional, impmax_maximumadaptivecapacity) {
    ## calculate adjusted tolerable level and max impact based on adaptation policy
    if ((y_year - pstart_startdateofadaptpolicy) < 0)
        atl_adjustedtolerablelevel.ttrr = 0
    else if (((y_year - pstart_startdateofadaptpolicy) / pyears_yearstilfulleffect) < 1.)
        atl_adjustedtolerablelevel.ttrr =
            ((y_year - pstart_startdateofadaptpolicy) / pyears_yearstilfulleffect) *
            plateau_increaseintolerableplateaufromadaptation
    else
        atl_adjustedtolerablelevel.ttrr = plateau_increaseintolerableplateaufromadaptation

    if ((y_year - istart_startdate) < 0)
        imp_adaptedimpacts.ttrr = 0
    else if (((y_year - istart_startdate) / iyears_yearstilfulleffect) < 1)
        imp_adaptedimpacts.ttrr =
            (y_year - istart_startdate) / iyears_yearstilfulleffect *
            impred_eventualpercentreduction
    else
        imp_adaptedimpacts.ttrr = impred_eventualpercentreduction

    ## Hope (2009),  25, equations 1-2
    cp_costplateau_regional = cp_costplateau_eu * cf_costregional
    ci_costimpact_regional = ci_costimpact_eu * cf_costregional

    ## Hope (2009),  25, equations 3-4
    acp_adaptivecostplateau.ttrr.percgdp = atl_adjustedtolerablelevel.ttrr * cp_costplateau_regional * autofac_autonomoustechchangefraction
    aci_adaptivecostimpact.ttrr.percgdp = imp_adaptedimpacts.ttrr * ci_costimpact_regional * impmax_maximumadaptivecapacity * autofac_autonomoustechchangefraction

    ## Hope (2009),  25, equation 5
    ac_adaptivecosts.ttrr.percgdp = acp_adaptivecostplateau.ttrr.percgdp + aci_adaptivecostimpact.ttrr.percgdp

    data.frame(year=y_year, region, acp=acp_adaptivecostplateau.ttrr.percgdp, aci=aci_adaptivecostimpact.ttrr.percgdp)
}

results <- data.frame()

for (tt in 1:length(y_years)) {
    auto_autonomoustechchangepercent = (1 - automult_autonomoustechchange^(1 / (y_year_lssp - y_year_0))) * 100 # % per year
    autofac_autonomoustechchangefraction = (1 - auto_autonomoustechchangepercent / 100)^(y_years[tt] - y_year_0) # Varies by year

    for (rr in 1:length(impmax_maximumadaptivecapacitys)) {
        subres <- calc.adaptcosts(y_years[tt], rr, autofac_autonomoustechchangefraction,
                                  pstart_startdateofadaptpolicys[rr], pyears_yearstilfulleffects[rr], plateau_increaseintolerableplateaufromadaptations[rr],
                                  istart_startdates[rr], iyears_yearstilfulleffects[rr], impred_eventualpercentreductions[rr],
                                  cf_costregionals[rr], impmax_maximumadaptivecapacitys[rr])

        results <- rbind(results, subres)
    }
}
