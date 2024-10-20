@defcomp MarketDamagesBurke_regional begin
    region = Index()
    country = Index()

    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")

    ## Country-level inputs for mix-and-match
    rtl_realizedtemperature_absolute = Parameter(index=[time, country], unit="degreeC")
    rcons_per_cap_SLRRemainConsumption = Parameter(index=[time, country], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP = Parameter(index=[time, country], unit="\$/person")
    gdp = Parameter(index=[time, country], unit="\$M")
    pop_population = Parameter(index=[time, country], unit="million person")

    rtl_0_realizedtemperature_absolute = Parameter(index=[country], unit="degreeC")
    rtl_0_realizedtemperature_change = Parameter(index=[country], unit="degreeC")

    # incoming parameters from Climate
    rtl_realizedtemperature_regional = Parameter(index=[time, region], unit="degreeC")

    # tolerability and impact variables from PAGE damages that Burke damages also require
    rcons_per_cap_SLRRemainConsumption_regional = Parameter(index=[time, region], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP_regional = Parameter(index=[time, region], unit="\$/person")
    save_savingsrate = Parameter(unit="%", default=15.)
    wincf_weightsfactor_market = Parameter(index=[region], unit="")
    ipow_MarketIncomeFxnExponent = Parameter(default=0.0)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)

    # added impact parameters and variables specifically for Burke damage function
    rtl_abs_0_realizedabstemperature = Parameter(index=[region]) # 1979-2005 means, Yumashev et al. 2019 Supplementary Table 16, table in /data directory
    rtl_0_realizedtemperature = Parameter(index=[region]) # temperature change between PAGE base year temperature and rtl_abs_0 (?)
    impf_coeff_lin = Parameter(default=-0.00829990966469437) # rescaled coefficients from Burke
    impf_coeff_quadr = Parameter(default=-0.000500003403703578)
    tcal_burke = Parameter(default=21.) # calibration temperature for the impact function
    nlag_burke = Parameter(default=1.) # Yumashev et al. (2019) allow for one or two lags

    i_burke_regionalimpact = Variable(index=[time, region], unit="degreeC") # Burke-specific warming impact, unlike PAGE-specific impact in absolute temperatures
    i1log_impactlogchange = Variable(index=[time, region]) # intermediate variable for computation

    # impact variables from PAGE damages that Burke damages also require
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_MarketRemainConsumption_regional = Variable(index=[time, region], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP_regional = Variable(index=[time, region], unit="\$/person")
    iref_ImpactatReferenceGDPperCap = Variable(index=[time, region])
    igdp_ImpactatActualGDPperCap = Variable(index=[time, region])

    isat_ImpactinclSaturationandAdaptation_regional = Variable(index=[time,region], unit="\$")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation_regional = Variable(index=[time,region], unit="\$/person")

    ## Country-level outputs for mix-and-match
    rcons_per_cap_MarketRemainConsumption = Variable(index=[time, country], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP = Variable(index=[time, country], unit="\$/person")
    isat_per_cap_ImpactinclSaturationandAdaptation = Variable(index=[time,country], unit="\$/person")

    function run_timestep(p, v, d, t)
        ## Translate from country to region for mix-and-match
        rtl_realizedtemperature_change = v.rtl_realizedtemperature_absolute[t, :] + p.rtl_0_realizedtemperature_change - p.rtl_0_realizedtemperature_absolute
        rtl_realizedtemperature_regional[t, :] = countrytoregion(model, weighted_mean, p.rtl_realizedtemperature_change, p.area)

        rcons_per_cap_SLRRemainConsumption_regional[t, :] = countrytoregion(model, weighted_mean, p.rcons_per_cap_SLRRemainConsumption[t, :], p.pop_population)
        rgdp_per_cap_SLRRemainGDP_regional[t, :] = countrytoregion(model, weighted_mean, p.rgdp_per_cap_SLRRemainGDP[t, :], p.pop_population)

        for r in d.region

            # calculate the regional temperature impact relative to baseline year and add it to baseline absolute value
            v.i_burke_regionalimpact[t,r] = (rtl_realizedtemperature_regional[t,r] - p.rtl_0_realizedtemperature[r]) + p.rtl_abs_0_realizedabstemperature[r]


            # calculate the log change, depending on the number of lags specified
            v.i1log_impactlogchange[t,r] = p.nlag_burke * (p.impf_coeff_lin  * (v.i_burke_regionalimpact[t,r] - p.rtl_abs_0_realizedabstemperature[r]) +
                                p.impf_coeff_quadr * ((v.i_burke_regionalimpact[t,r] - p.tcal_burke)^2 -
                                                      (p.rtl_abs_0_realizedabstemperature[r] - p.tcal_burke)^2))

            # calculate the impact at focus region GDP p.c.
            v.iref_ImpactatReferenceGDPperCap[t,r] = 100 * p.wincf_weightsfactor_market[r] * (1 - exp(v.i1log_impactlogchange[t,r]))

            # calculate impacts at actual GDP
            v.igdp_ImpactatActualGDPperCap[t,r] = v.iref_ImpactatReferenceGDPperCap[t,r] *
                (rgdp_per_cap_SLRRemainGDP_regional[t,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_MarketIncomeFxnExponent

            # send impacts down a logistic path if saturation threshold is exceeded
            if v.igdp_ImpactatActualGDPperCap[t,r] < p.isatg_impactfxnsaturation
                v.isat_ImpactinclSaturationandAdaptation_regional[t,r] = v.igdp_ImpactatActualGDPperCap[t,r]
            else
                v.isat_ImpactinclSaturationandAdaptation_regional[t,r] = p.isatg_impactfxnsaturation +
                    ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
                    ((v.igdp_ImpactatActualGDPperCap[t,r] - p.isatg_impactfxnsaturation) /
                    (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
                    (v.igdp_ImpactatActualGDPperCap[t,r] -
                    p.isatg_impactfxnsaturation)))
            end

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_regional[t,r] = (v.isat_ImpactinclSaturationandAdaptation_regional[t,r] / 100) * rgdp_per_cap_SLRRemainGDP_regional[t,r]
            v.rcons_per_cap_MarketRemainConsumption_regional[t,r] = rcons_per_cap_SLRRemainConsumption_regional[t,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_regional[t,r]
            v.rgdp_per_cap_MarketRemainGDP_regional[t,r] = v.rcons_per_cap_MarketRemainConsumption_regional[t,r] / (1 - p.save_savingsrate / 100)
        end

        ## Translate from region to country for mix-and-match
        v.isat_per_cap_ImpactinclSaturationandAdaptation[t, :] = regiontocountry(p.model, v.isat_per_cap_ImpactinclSaturationandAdaptation_regional[t, :])
        v.rcons_per_cap_MarketRemainConsumption[t, :] = p.rcons_per_cap_SLRRemainConsumption[t, :] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t, :]
        v.rgdp_per_cap_MarketRemainGDP[t, :] = v.rcons_per_cap_MarketRemainConsumption[t,r] / (1 - p.save_savingsrate / 100)
    end
end

# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.

function addmarketdamagesburke_regional(model::Model)
    marketdamagesburkecomp = add_comp!(model, MarketDamagesBurke_regional, :MarketDamagesBurke)

    marketdamagesburke[:model] = model
    marketdamagesburkecomp[:rtl_abs_0_realizedabstemperature] = readpagedata(model, "data/rtl_abs_0_realizedabstemperature.csv")
    marketdamagesburkecomp[:rtl_0_realizedtemperature] = readpagedata(model, "data/rtl_0_realizedtemperature.csv")

    ## Parameters for mix-and-match
    climtemp[:rtl_0_realizedtemperature_absolute] = get_countryinfo().Temp2010
    climtemp[:rtl_0_realizedtemperature_change] = regiontocountry(model, readpagedata(model, "data/rtl_0_realizedtemperature.csv"))

    # fix the current bug which implements the regional weights from SLR and discontinuity also for market and non-market damages (where weights should be uniformly one)
    marketdamagesburkecomp[:wincf_weightsfactor_market] = readpagedata(model, "data/wincf_weightsfactor_market.csv")

    return marketdamagesburkecomp
end
