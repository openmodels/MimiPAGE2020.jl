include("../utils/country_tools.jl")

@defcomp NonMarketDamages begin
    region = Index()

    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")

    # incoming parameters from Climate
    rtl_realizedtemperature = Parameter(index=[time, country], unit="degreeC")

    # tolerability parameters
    impmax_maxtempriseforadaptpolicyNM = Parameter(index=[region], unit="degreeC")
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC")
    imp_actualreduction = Parameter(index=[time, region], unit="%")

    # tolerability variables
    i_regionalimpact = Variable(index=[time, country], unit="degreeC")

    # impact Parameters
    rcons_per_cap_MarketRemainConsumption = Parameter(index=[time, country], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, country], unit="\$/person")

    save_savingsrate = Parameter(unit="%", default=15.)
    wincf_weightsfactor_nonmarket = Parameter(index=[region], unit="")
    w_NonImpactsatCalibrationTemp = Parameter(unit="%GDP", default=0.487 * 1.25 * 3*3) # 125% of negative of mkt_t2 coefficient from Howard & Sterner 2017
    ipow_NonMarketIncomeFxnExponent = Parameter(unit="unitless", default=0.)
    iben_NonMarketInitialBenefit = Parameter(unit="%GDP/degreeC", default=0.08333333333333333)
    tcal_CalibrationTemp = Parameter(unit="degreeC", default=3.)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)
    pow_NonMarketExponent = Parameter(unit="", default=2.1666666666666665)

    # impact variables
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_NonMarketRemainConsumption = Variable(index=[time, country], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, country], unit="\$/person")
    iref_ImpactatReferenceGDPperCap = Variable(index=[time, country], unit="%")
    igdp_ImpactatActualGDPperCap = Variable(index=[time, country], unit="%")
    isat_ImpactinclSaturationandAdaptation = Variable(index=[time,country], unit="\$")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,country], unit="\$/person")

    function run_timestep(p, v, d, t)
        impmax_maxtempriseforadaptpolicyNM_country = regiontocountry(p.model, p.impmax_maxtempriseforadaptpolicyNM)
        atl_adjustedtolerableleveloftemprise_country = regiontocountry(p.model, p.atl_adjustedtolerableleveloftemprise[t, :])
        imp_actualreduction_country = regiontocountry(p.model, p.imp_actualreduction[t, :])
        wincf_weightsfactor_nonmarket_country = regiontocountry(p.model, p.wincf_weightsfactor_nonmarket)

        for cc in d.country
            if p.rtl_realizedtemperature[t,cc] - atl_adjustedtolerableleveloftemprise_country[cc] < 0
                v.i_regionalimpact[t,cc] = 0
            else
                v.i_regionalimpact[t,cc] = p.rtl_realizedtemperature[t,cc] - atl_adjustedtolerableleveloftemprise_country[cc]
            end

            v.iref_ImpactatReferenceGDPperCap[t,cc] = wincf_weightsfactor_nonmarket_country[cc] *
                ((p.w_NonImpactsatCalibrationTemp + p.iben_NonMarketInitialBenefit * p.tcal_CalibrationTemp) *
                    (v.i_regionalimpact[t,cc] / p.tcal_CalibrationTemp)^p.pow_NonMarketExponent - v.i_regionalimpact[t,cc] * p.iben_NonMarketInitialBenefit)

            v.igdp_ImpactatActualGDPperCap[t,cc] = v.iref_ImpactatReferenceGDPperCap[t,cc] *
                (p.rgdp_per_cap_MarketRemainGDP[t,cc] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_NonMarketIncomeFxnExponent

            if v.igdp_ImpactatActualGDPperCap[t,cc] < p.isatg_impactfxnsaturation
                v.isat_ImpactinclSaturationandAdaptation[t,cc] = v.igdp_ImpactatActualGDPperCap[t,cc]
            else
                v.isat_ImpactinclSaturationandAdaptation[t,cc] = p.isatg_impactfxnsaturation +
                ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
                ((v.igdp_ImpactatActualGDPperCap[t,cc] - p.isatg_impactfxnsaturation) /
                 (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
                  (v.igdp_ImpactatActualGDPperCap[t,cc] -
                   p.isatg_impactfxnsaturation)))
            end

            if v.i_regionalimpact[t,cc] < impmax_maxtempriseforadaptpolicyNM_country[cc]
                v.isat_ImpactinclSaturationandAdaptation[t,cc] = v.isat_ImpactinclSaturationandAdaptation[t,cc] * (1 - imp_actualreduction_country[cc] / 100)
            else
                v.isat_ImpactinclSaturationandAdaptation[t,cc] = v.isat_ImpactinclSaturationandAdaptation[t,cc] *
                    (1 - (imp_actualreduction_country[cc] / 100) * impmax_maxtempriseforadaptpolicyNM_country[cc] /
                     v.i_regionalimpact[t,cc])
            end

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,cc] = (v.isat_ImpactinclSaturationandAdaptation[t,cc] / 100) * p.rgdp_per_cap_MarketRemainGDP[t,cc]
            v.rcons_per_cap_NonMarketRemainConsumption[t,cc] = p.rcons_per_cap_MarketRemainConsumption[t,cc] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,cc]
            v.rgdp_per_cap_NonMarketRemainGDP[t,cc] = v.rcons_per_cap_NonMarketRemainConsumption[t,cc] / (1 - p.save_savingsrate / 100)
        end
    end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addnonmarketdamages(model::Model, use_page09weights::Bool=false)
    nonmarketdamagescomp = add_comp!(model, NonMarketDamages)
    nonmarketdamagescomp[:model] = model

    nonmarketdamagescomp[:impmax_maxtempriseforadaptpolicyNM] = readpagedata(model, "data/impmax_noneconomic.csv")
    nonmarketdamagescomp[:wincf_weightsfactor_nonmarket] = readpagedata(model, "data/wincf_weightsfactor_nonmarket.csv")

    return nonmarketdamagescomp
end
