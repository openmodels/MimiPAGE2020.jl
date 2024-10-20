@defcomp NonMarketDamages_regional begin
    region = Index()
    country = Index()

    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")

    ## Country-level inputs for mix-and-match
    rtl_realizedtemperature_change = Parameter(index=[time, country], unit="degreeC")
    rt_g_globaltemperature = Parameter(index=[time], unit="degreeC")
    rtl_g_landtemperature = Parameter(index=[time], unit="degreeC")
    rcons_per_cap_MarketRemainConsumption = Parameter(index=[time, country], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, country], unit="\$/person")
    pop_population = Parameter(index=[time, country], unit="million person")

    # incoming parameters from Climate
    rtl_realizedtemperature_regional = Parameter(index=[time, region], unit="degreeC")

    # tolerability parameters
    impmax_maxtempriseforadaptpolicyNM = Parameter(index=[region], unit="degreeC")
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC")
    imp_actualreduction = Parameter(index=[time, region], unit="%")

    # tolerability variables
    i_regionalimpact = Variable(index=[time, region], unit="degreeC")

    # impact Parameters
    rcons_per_cap_MarketRemainConsumption_regional = Parameter(index=[time, region], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP_regional = Parameter(index=[time, region], unit="\$/person")

    save_savingsrate = Parameter(unit="%", default=15.)
    wincf_weightsfactor_nonmarket = Parameter(index=[region], unit="")
    w_NonImpactsatCalibrationTemp = Parameter(unit="%GDP", default=0.6333333333333333)
    ipow_NonMarketIncomeFxnExponent = Parameter(unit="unitless", default=0.)
    iben_NonMarketInitialBenefit = Parameter(unit="%GDP/degreeC", default=0.08333333333333333)
    tcal_CalibrationTemp = Parameter(unit="degreeC", default=3.)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)
    pow_NonMarketExponent = Parameter(unit="", default=2.1666666666666665)

    # impact variables
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_NonMarketRemainConsumption = Variable(index=[time, region], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, region], unit="\$/person")
    iref_ImpactatReferenceGDPperCap = Variable(index=[time, region], unit="%")
    igdp_ImpactatActualGDPperCap = Variable(index=[time, region], unit="%")
    isat_ImpactinclSaturationandAdaptation = Variable(index=[time,region], unit="\$")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,region], unit="\$/person")

    ## Country-level outputs for mix-and-match
    rcons_per_cap_NonMarketRemainConsumption = Variable(index=[time, country], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, country], unit="\$/person")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,country], unit="\$/person")

    function run_timestep(p, v, d, t)
        ## Translate from country to region for mix-and-match
        rtl_realizedtemperature_regional[t, :] = countrytoregion(p.model, weighted_mean, p.rtl_realizedtemperature_change, p.area)
        rcons_per_cap_MarketRemainConsumption_regional[t, :] = countrytoregion(p.model, weighted_mean, p.rcons_per_cap_MarketRemainConsumption[t, :], p.pop_population)
        rgdp_per_cap_MarketRemainGDP_regional[t, :] = countrytoregion(p.model, weighted_mean, p.rcons_per_cap_MarketRemainConsumption[t, :], p.pop_population)

        for r in d.region

            if rtl_realizedtemperature_regional[t,r] - p.atl_adjustedtolerableleveloftemprise[t,r] < 0
                v.i_regionalimpact[t,r] = 0
            else
                v.i_regionalimpact[t,r] = rtl_realizedtemperature_regional[t,r] - p.atl_adjustedtolerableleveloftemprise[t,r]
            end

            v.iref_ImpactatReferenceGDPperCap[t,r] = p.wincf_weightsfactor_nonmarket[r] *
                ((p.w_NonImpactsatCalibrationTemp + p.iben_NonMarketInitialBenefit * p.tcal_CalibrationTemp) *
                    (v.i_regionalimpact[t,r] / p.tcal_CalibrationTemp)^p.pow_NonMarketExponent - v.i_regionalimpact[t,r] * p.iben_NonMarketInitialBenefit)

            v.igdp_ImpactatActualGDPperCap[t,r] = v.iref_ImpactatReferenceGDPperCap[t,r] *
                (rgdp_per_cap_MarketRemainGDP_regional[t,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_NonMarketIncomeFxnExponent

            if v.igdp_ImpactatActualGDPperCap[t,r] < p.isatg_impactfxnsaturation
                v.isat_ImpactinclSaturationandAdaptation[t,r] = v.igdp_ImpactatActualGDPperCap[t,r]
            else
                v.isat_ImpactinclSaturationandAdaptation[t,r] = p.isatg_impactfxnsaturation +
                ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
                ((v.igdp_ImpactatActualGDPperCap[t,r] - p.isatg_impactfxnsaturation) /
                 (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
                  (v.igdp_ImpactatActualGDPperCap[t,r] -
                   p.isatg_impactfxnsaturation)))
            end

            if v.i_regionalimpact[t,r] < p.impmax_maxtempriseforadaptpolicyNM[r]
                v.isat_ImpactinclSaturationandAdaptation[t,r] = v.isat_ImpactinclSaturationandAdaptation[t,r] * (1 - p.imp_actualreduction[t,r] / 100)
            else
                v.isat_ImpactinclSaturationandAdaptation[t,r] = v.isat_ImpactinclSaturationandAdaptation[t,r] *
                    (1 - (p.imp_actualreduction[t,r] / 100) * p.impmax_maxtempriseforadaptpolicyNM[r] /
                     v.i_regionalimpact[t,r])
            end

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptation[t,r] / 100) * rgdp_per_cap_MarketRemainGDP_regional[t,r]
            v.rcons_per_cap_NonMarketRemainConsumption[t,r] = rcons_per_cap_MarketRemainConsumption_regional[t,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r]
            v.rgdp_per_cap_NonMarketRemainGDP[t,r] = v.rcons_per_cap_NonMarketRemainConsumption[t,r] / (1 - p.save_savingsrate / 100)
        end

        ## Translate from region to country for mix-and-match
        v.isat_per_cap_ImpactinclSaturationandAdaptation[t, :] = regiontocountry(p.model, v.isat_per_cap_ImpactinclSaturationandAdaptation_regional[t, :])
        v.rcons_per_cap_NonMarketRemainConsumption[t, :] = p.rcons_per_cap_MarketRemainConsumption[t, :] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t, :]
        v.rgdp_per_cap_NonMarketRemainGDP[t, :] = v.rcons_per_cap_NonMarketRemainConsumption[t,r] / (1 - p.save_savingsrate / 100)
    end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addnonmarketdamages_regional(model::Model, use_page09weights::Bool=false)
    nonmarketdamagescomp = add_comp!(model, NonMarketDamages_regional, :NonMarketDamages)
    nonmarketdamagescomp[:impmax_maxtempriseforadaptpolicyNM] = readpagedata(model, "data/impmax_noneconomic.csv")

    # fix the current bug which implements the regional weights from SLR and discontinuity also for market and non-market damages (where weights should be uniformly one)
    if use_page09weights
        nonmarketdamagescomp[:wincf_weightsfactor_nonmarket] = readpagedata(model, "data/wincf_weightsfactor_sea.csv")
    else
        nonmarketdamagescomp[:wincf_weightsfactor_nonmarket] = readpagedata(model, "data/wincf_weightsfactor_nonmarket.csv")
    end

    return nonmarketdamagescomp
end
