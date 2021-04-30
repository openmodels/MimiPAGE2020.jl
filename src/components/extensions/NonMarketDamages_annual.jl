function interpolate_parameters_nonmarketdamages(p, v, d, t)
    # interpolation of parameters, see notes in run_timestep for why these parameters
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            yr = annual_year - 2015 + 1
            for r in d.region
                v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r]
                v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r]
            end
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - gettime(t - 1)
            fraction_timestep = frac / ((gettime(t)) - (gettime(t - 1)))

            for r in d.region
                if use_linear
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r] * (fraction_timestep) + p.atl_adjustedtolerableleveloftemprise[t - 1, r] * (1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r] * (fraction_timestep) + p.imp_actualreduction[t - 1, r] * (1 - fraction_timestep)
                elseif use_logburke
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r]^(fraction_timestep) * p.atl_adjustedtolerableleveloftemprise[t - 1, r]^(1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] =  p.imp_actualreduction[t, r]^(fraction_timestep) * p.imp_actualreduction[t - 1, r]^(1 - fraction_timestep)
                elseif use_logpopulation
                    # all linear.
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r] * (fraction_timestep) + p.atl_adjustedtolerableleveloftemprise[t - 1, r] * (1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] = p.imp_actualreduction[t, r] * (fraction_timestep) + p.imp_actualreduction[t - 1, r] * (1 - fraction_timestep)
                elseif use_logwherepossible
                    v.atl_adjustedtolerableleveloftemprise_ann[yr, r] = p.atl_adjustedtolerableleveloftemprise[t, r]^(fraction_timestep) * p.atl_adjustedtolerableleveloftemprise[t - 1, r]^(1 - fraction_timestep)
                    v.imp_actualreduction_ann[yr, r] =  p.imp_actualreduction[t, r]^(fraction_timestep) * p.imp_actualreduction[t - 1, r]^(1 - fraction_timestep)
                else
                    error("NO INTERPOLATION METHOD SELECTED! Specify linear or logarithmic interpolation.")
                end

            end
        end
    end
end

function calc_nonmarketdamages(p, v, d, t, annual_year, r)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia


    if p.rtl_realizedtemperature_ann[yr,r] - v.atl_adjustedtolerableleveloftemprise_ann[yr,r] < 0
        v.i_regionalimpact_ann[yr,r] = 0
    else
        v.i_regionalimpact_ann[yr,r] = p.rtl_realizedtemperature_ann[yr,r] - v.atl_adjustedtolerableleveloftemprise_ann[yr,r]
    end

    v.iref_ImpactatReferenceGDPperCap_ann[yr,r] = p.wincf_weightsfactor_nonmarket[r] *
        ((p.w_NonImpactsatCalibrationTemp + p.iben_NonMarketInitialBenefit * p.tcal_CalibrationTemp) *
            (v.i_regionalimpact_ann[yr,r] / p.tcal_CalibrationTemp)^p.pow_NonMarketExponent - v.i_regionalimpact_ann[yr,r] * p.iben_NonMarketInitialBenefit)

    v.igdp_ImpactatActualGDPperCap_ann[yr,r] = v.iref_ImpactatReferenceGDPperCap_ann[yr,r] *
        (p.rgdp_per_cap_MarketRemainGDP_ann[yr,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_NonMarketIncomeFxnExponent

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

    if v.i_regionalimpact_ann[yr,r] <= p.impmax_maxtempriseforadaptpolicyNM[r]
        v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] = v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] * (1 - v.imp_actualreduction_ann[yr,r] / 100)
    else
        temp = v.isat_ImpactinclSaturationandAdaptation_ann[yr,r]
        v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] = temp * (1 - (v.imp_actualreduction_ann[yr,r] / 100) * p.impmax_maxtempriseforadaptpolicyNM[r] / v.i_regionalimpact_ann[yr,r])
    end

    v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann[yr,r] = (v.isat_ImpactinclSaturationandAdaptation_ann[yr,r] / 100) * p.rgdp_per_cap_MarketRemainGDP_ann[yr,r]
    v.rcons_per_cap_NonMarketRemainConsumption_ann[yr,r] = p.rcons_per_cap_MarketRemainConsumption_ann[yr,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann[yr,r]
    v.rgdp_per_cap_NonMarketRemainGDP_ann[yr,r] = v.rcons_per_cap_NonMarketRemainConsumption_ann[yr,r] / (1 - p.save_savingsrate / 100)
end


@defcomp NonMarketDamages begin

    region = Index()
    year = Index()

    y_year = Parameter(index=[time], unit="year")
    y_year_ann = Parameter(index=[year], unit="year")
    yagg_periodspan = Parameter(index=[time], unit="year") # for in-component summation

    # incoming parameters from Climate
    rtl_realizedtemperature = Parameter(index=[time, region], unit="degreeC")
    rtl_realizedtemperature_ann = Parameter(index=[year, region], unit="degreeC")

    # tolerability parameters
    impmax_maxtempriseforadaptpolicyNM = Parameter(index=[region], unit="degreeC")
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC")
    atl_adjustedtolerableleveloftemprise_ann = Variable(index=[year,region], unit="degreeC")
    imp_actualreduction = Parameter(index=[time, region], unit="%")
    imp_actualreduction_ann = Variable(index=[year, region], unit="%")

    # tolerability variables
    i_regionalimpact = Variable(index=[time, region], unit="degreeC")
    i_regionalimpact_ann = Variable(index=[year, region], unit="degreeC")

    # impact Parameters
    rcons_per_cap_MarketRemainConsumption = Parameter(index=[time, region], unit="\$/person")
    rcons_per_cap_MarketRemainConsumption_ann = Parameter(index=[year, region], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, region], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP_ann = Parameter(index=[year, region], unit="\$/person")

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
    rcons_per_cap_NonMarketRemainConsumption_ann = Variable(index=[year, region], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, region], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP_sum = Variable(unit="\$/person") # for analysis
    rgdp_per_cap_NonMarketRemainGDP_ann = Variable(index=[year, region], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP_ann_sum = Variable(unit="\$/person") # for analysis
    iref_ImpactatReferenceGDPperCap = Variable(index=[time, region], unit="%")
    iref_ImpactatReferenceGDPperCap_ann = Variable(index=[year, region], unit="%")
    igdp_ImpactatActualGDPperCap = Variable(index=[time, region], unit="%")
    igdp_ImpactatActualGDPperCap_ann = Variable(index=[year, region], unit="%")
    isat_ImpactinclSaturationandAdaptation = Variable(index=[time,region], unit="\$")
    isat_ImpactinclSaturationandAdaptation_ann = Variable(index=[year, region], unit="\$")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,region], unit="\$/person")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann = Variable(index=[year, region], unit="\$/person")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann_sum_nonmarket = Variable(unit="\$/person") # for analysis


    function run_timestep(p, v, d, t)

        # interpolate the parameters that require interpolation:
    interpolate_parameters_nonmarketdamages(p, v, d, t)

    for r in d.region

        if p.rtl_realizedtemperature[t,r] - p.atl_adjustedtolerableleveloftemprise[t,r] < 0
            v.i_regionalimpact[t,r] = 0
        else
            v.i_regionalimpact[t,r] = p.rtl_realizedtemperature[t,r] - p.atl_adjustedtolerableleveloftemprise[t,r]
        end

        v.iref_ImpactatReferenceGDPperCap[t,r] = p.wincf_weightsfactor_nonmarket[r] *
                ((p.w_NonImpactsatCalibrationTemp + p.iben_NonMarketInitialBenefit * p.tcal_CalibrationTemp) *
                    (v.i_regionalimpact[t,r] / p.tcal_CalibrationTemp)^p.pow_NonMarketExponent - v.i_regionalimpact[t,r] * p.iben_NonMarketInitialBenefit)

        v.igdp_ImpactatActualGDPperCap[t,r] = v.iref_ImpactatReferenceGDPperCap[t,r] *
                (p.rgdp_per_cap_MarketRemainGDP[t,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_NonMarketIncomeFxnExponent

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

        v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptation[t,r] / 100) * p.rgdp_per_cap_MarketRemainGDP[t,r]
        v.rcons_per_cap_NonMarketRemainConsumption[t,r] = p.rcons_per_cap_MarketRemainConsumption[t,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r]
        v.rgdp_per_cap_NonMarketRemainGDP[t,r] = v.rcons_per_cap_NonMarketRemainConsumption[t,r] / (1 - p.save_savingsrate / 100)

            # calculate  for this specific year
        if is_first(t)
            for annual_year = 2015:(gettime(t))
                calc_nonmarketdamages(p, v, d, t, annual_year, r)
            end
            if isequal(r, 8)
                v.rgdp_per_cap_NonMarketRemainGDP_sum = sum(v.rgdp_per_cap_NonMarketRemainGDP[t,:]) * p.yagg_periodspan[t]
            end
        else
            for annual_year = (gettime(t - 1) + 1):(gettime(t))
                calc_nonmarketdamages(p, v, d, t, annual_year, r)

                if isequal(annual_year, 2300)
                    if isequal(r, 8)
                        v.rgdp_per_cap_NonMarketRemainGDP_ann_sum = sum(v.rgdp_per_cap_NonMarketRemainGDP_ann[:,:])
                        v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann_sum_nonmarket = sum(v.isat_per_cap_ImpactperCapinclSaturationandAdaptation_ann[:,:])
                    end
                end
            end
            if isequal(r, 8)
                v.rgdp_per_cap_NonMarketRemainGDP_sum = v.rgdp_per_cap_NonMarketRemainGDP_sum + sum(v.rgdp_per_cap_NonMarketRemainGDP[t,:]) * p.yagg_periodspan[t]
            end
        end
    end
end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addnonmarketdamages(model::Model)
    nonmarketdamagescomp = add_comp!(model, NonMarketDamages)
    nonmarketdamagescomp[:impmax_maxtempriseforadaptpolicyNM] = readpagedata(model, "data/impmax_noneconomic.csv")

    # fix the current bug which implements the regional weights from SLR and discontinuity also for market and non-market damages (where weights should be uniformly one)
    nonmarketdamagescomp[:wincf_weightsfactor_nonmarket] = readpagedata(model, "data/wincf_weightsfactor_nonmarket.csv")

    return nonmarketdamagescomp
end
