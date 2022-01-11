@defcomp MarketDamages_annual begin

    region = Index()
    year = Index()

    # Configuration

    interpolate_parameters = Parameter{Bool}(default=false)

    # Parameters and Variable

    # incoming parameters from Climate
    rtl_realizedtemperature_ann = Parameter(index=[year, region], unit="degreeC")

    # tolerability variables
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC")
    atl_adjustedtolerableleveloftemprise_ann = Variable(index=[year,region], unit="degreeC")
    imp_actualreduction = Parameter(index=[time, region], unit="%")
    imp_actualreduction_ann = Variable(index=[year, region], unit="%")
    i_regionalimpact_ann = Variable(index=[year, region], unit="degreeC")

    # impact Parameters
    rcons_per_cap_SLRRemainConsumption = Parameter(index=[time, region], unit="\$/person")
    rcons_per_cap_SLRRemainConsumption_ann = Variable(index=[year, region], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP = Parameter(index=[time, region], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP_ann = Variable(index=[year, region], unit="\$/person")

    save_savingsrate = Parameter(unit="%", default=15.)
    wincf_weightsfactor_market = Parameter(index=[region], unit="unitless")
    W_MarketImpactsatCalibrationTemp = Parameter(unit="%GDP", default=0.6)
    ipow_MarketIncomeFxnExponent = Parameter(default=-0.13333333333333333)
    iben_MarketInitialBenefit = Parameter(default=.1333333333333)
    tcal_CalibrationTemp = Parameter(unit="degreeC", default=3.)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)

    # impact variables
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_MarketRemainConsumption_ann = Variable(index=[year, region], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP_ann = Variable(index=[year, region], unit="\$/person")
    iref_ImpactatReferenceGDPperCap_ann = Variable(index=[year, region])
    igdp_ImpactatActualGDPperCap_ann = Variable(index=[year, region])
    impmax_maxtempriseforadaptpolicyM = Parameter(index=[region], unit="degreeC")

    isat_ImpactinclSaturationandAdaptation_ann = Variable(index=[year, region])
    isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann = Variable(index=[year, region], unit="\$/person")
    pow_MarketImpactExponent = Parameter(unit="", default=2.1666666666666665)

    function run_timestep(p, v, d, t)

        if p.interpolate_parameters
            # interpolate the parameters that require interpolation:
            interpolate_parameters_marketdamages(p, v, d, t)
        end

        for r in d.region
            # calculate  for this specific year
            if is_first(t)
                for annual_year = 2015:(gettime(t))
                    calc_marketdamages(p, v, d, t, annual_year, r)
                end
            else
                for annual_year = (gettime(t - 1) + 1):(gettime(t))
                    calc_marketdamages(p, v, d, t, annual_year, r)
                end
            end
        end

    end
end

# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.

function addmarketdamages_annual(model::Model)
    marketdamagescomp = add_comp!(model, MarketDamages_annual)
    marketdamagescomp[:impmax_maxtempriseforadaptpolicyM] = readpagedata(model, "data/impmax_economic.csv")

    # fix the current bug which implements the regional weights from SLR and discontinuity also for market and non-market damages (where weights should be uniformly one)
    marketdamagescomp[:wincf_weightsfactor_market] = readpagedata(model, "data/wincf_weightsfactor_market.csv")

    return marketdamagescomp
end

function interpolate_parameters_marketdamages(p, v, d, t)
    # interpolation of parameters, see notes in run_timestep for why these parameters
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            yr = annual_year - 2015 + 1
            for r in d.region

                # for the years before 2020, we assume the numbers to be the same as the figures of 2020
                v.rcons_per_cap_SLRRemainConsumption_ann[yr, r] = p.rcons_per_cap_SLRRemainConsumption[t, r]
                v.rgdp_per_cap_SLRRemainGDP_ann[yr, r] = p.rgdp_per_cap_SLRRemainGDP[t, r]
                v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r]
                v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r]
            end
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - gettime(t - 1)
            fraction_timestep = frac / ((gettime(t)) - (gettime(t - 1))) # check if +1 might also need to feature here.

            for r in d.region
                if use_linear
                    # for the years after 2020, we use linear interpolation between the years of analysis
                    v.rcons_per_cap_SLRRemainConsumption_ann[yr, r] = p.rcons_per_cap_SLRRemainConsumption[t, r] * (fraction_timestep) + p.rcons_per_cap_SLRRemainConsumption[t - 1, r] * (1 - fraction_timestep)
                    v.rgdp_per_cap_SLRRemainGDP_ann[yr,r] = p.rgdp_per_cap_SLRRemainGDP[t, r] * (fraction_timestep) + p.rgdp_per_cap_SLRRemainGDP[t - 1, r] * (1 - fraction_timestep)
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r] * (fraction_timestep) + p.atl_adjustedtolerableleveloftemprise[t - 1, r] * (1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r] * (fraction_timestep) + p.imp_actualreduction[t - 1, r] * (1 - fraction_timestep)
                elseif use_logburke
                    v.rcons_per_cap_SLRRemainConsumption_ann[yr, r] = p.rcons_per_cap_SLRRemainConsumption[t, r]^(fraction_timestep) * p.rcons_per_cap_SLRRemainConsumption[t - 1, r]^(1 - fraction_timestep)
                    v.rgdp_per_cap_SLRRemainGDP_ann[yr,r] = p.rgdp_per_cap_SLRRemainGDP[t, r]^(fraction_timestep) * p.rgdp_per_cap_SLRRemainGDP[t - 1, r]^(1 - fraction_timestep)
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r]^(fraction_timestep) * p.atl_adjustedtolerableleveloftemprise[t - 1, r]^(1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r]^(fraction_timestep) * p.imp_actualreduction[t - 1, r]^(1 - fraction_timestep)
                elseif use_logpopulation
                    # all linear
                    v.rcons_per_cap_SLRRemainConsumption_ann[yr, r] = p.rcons_per_cap_SLRRemainConsumption[t, r] * (fraction_timestep) + p.rcons_per_cap_SLRRemainConsumption[t - 1, r] * (1 - fraction_timestep)
                    v.rgdp_per_cap_SLRRemainGDP_ann[yr,r] = p.rgdp_per_cap_SLRRemainGDP[t, r] * (fraction_timestep) + p.rgdp_per_cap_SLRRemainGDP[t - 1, r] * (1 - fraction_timestep)
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r] * (fraction_timestep) + p.atl_adjustedtolerableleveloftemprise[t - 1, r] * (1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r] * (fraction_timestep) + p.imp_actualreduction[t - 1, r] * (1 - fraction_timestep)
                elseif use_logwherepossible
                    v.rcons_per_cap_SLRRemainConsumption_ann[yr, r] = p.rcons_per_cap_SLRRemainConsumption[t, r]^(fraction_timestep) * p.rcons_per_cap_SLRRemainConsumption[t - 1, r]^(1 - fraction_timestep)
                    v.rgdp_per_cap_SLRRemainGDP_ann[yr,r] = p.rgdp_per_cap_SLRRemainGDP[t, r]^(fraction_timestep) * p.rgdp_per_cap_SLRRemainGDP[t - 1, r]^(1 - fraction_timestep)
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r]^(fraction_timestep) * p.atl_adjustedtolerableleveloftemprise[t - 1, r]^(1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r]^(fraction_timestep) * p.imp_actualreduction[t - 1, r]^(1 - fraction_timestep)
                else
                    error("NO INTERPOLATION METHOD SELECTED! Specify linear or logarithmic interpolation.")
                end

            end
        end
    end
end

function calc_marketdamages(p, v, d, t, annual_year, r)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    # calculate tolerability
    if (p.rtl_realizedtemperature_ann[yr,r] - v.atl_adjustedtolerableleveloftemprise_ann[yr,r]) < 0
        v.i_regionalimpact_ann[yr,r] = 0
    else
        v.i_regionalimpact_ann[yr,r] = p.rtl_realizedtemperature_ann[yr,r] - v.atl_adjustedtolerableleveloftemprise_ann[yr,r]
    end

    v.iref_ImpactatReferenceGDPperCap_ann[yr,r] = p.wincf_weightsfactor_market[r] * ((p.W_MarketImpactsatCalibrationTemp + p.iben_MarketInitialBenefit * p.tcal_CalibrationTemp) *
        (v.i_regionalimpact_ann[yr,r] / p.tcal_CalibrationTemp)^p.pow_MarketImpactExponent - v.i_regionalimpact_ann[yr,r] * p.iben_MarketInitialBenefit)

    v.igdp_ImpactatActualGDPperCap_ann[yr,r] = v.iref_ImpactatReferenceGDPperCap_ann[yr,r] *
        (v.rgdp_per_cap_SLRRemainGDP_ann[yr,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_MarketIncomeFxnExponent

    if v.igdp_ImpactatActualGDPperCap_ann[yr,r] < p.isatg_impactfxnsaturation
        v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] = v.igdp_ImpactatActualGDPperCap_ann[yr,r]
    else
        v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] = p.isatg_impactfxnsaturation +
            ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
            ((v.igdp_ImpactatActualGDPperCap_ann[yr,r] - p.isatg_impactfxnsaturation) /
            (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
            (v.igdp_ImpactatActualGDPperCap_ann[yr,r] -
            p.isatg_impactfxnsaturation)))
    end

    if v.i_regionalimpact_ann[yr,r] < p.impmax_maxtempriseforadaptpolicyM[r]
        v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] = v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] * (1 - v.imp_actualreduction_ann[yr,r] / 100)
    else
        v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] = v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] *
            (1 - (v.imp_actualreduction_ann[yr,r] / 100) * p.impmax_maxtempriseforadaptpolicyM[r] /
            v.i_regionalimpact_ann[yr,r])
    end

    v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann[yr,r] = (v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] / 100) * v.rgdp_per_cap_SLRRemainGDP_ann[yr,r]
    v.rcons_per_cap_MarketRemainConsumption_ann[yr,r] = v.rcons_per_cap_SLRRemainConsumption_ann[yr,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann[yr,r]
    v.rgdp_per_cap_MarketRemainGDP_ann[yr,r] = v.rcons_per_cap_MarketRemainConsumption_ann[yr,r] / (1 - p.save_savingsrate / 100)

    if v.rgdp_per_cap_MarketRemainGDP_ann[yr,r] < 0
        v.rgdp_per_cap_MarketRemainGDP_ann[yr,r] = 0
    end

end
