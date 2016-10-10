using DataFrames

@defcomp NonMarketDamages begin
    region = Index(region)

    y_year = Parameter(index=[time], unit="year")

    #incoming parameters from Climate
    rt_realizedtemperature = Parameter(index=[time, region], unit="degreeC")

    #tolerability parameters
    plateau_increaseintolerableplateaufromadaptationNM = Parameter(index=[region], unit="degreeC")
    pstart_startdateofadaptpolicyNM = Parameter(index=[region], unit="year")
    pyears_yearstilfulleffectNM = Parameter(index=[region], unit="year")
    impred_eventualpercentreductionNM = Parameter(index=[region], unit= "%")
    impmax_maxtempriseforadaptpolicyNM = Parameter(index=[region], unit= "degreeC")
    istart_startdateNM = Parameter(index=[region], unit = "year")
    iyears_yearstilfulleffectNM = Parameter(index=[region], unit= "year")

    #tolerability variables
    atl_adjustedtolerableleveloftemprise = Variable(index=[time,region], unit="degreeC")
    imp_actualreduction = Variable(index=[time, region], unit= "%")
    i_regionalimpact = Variable(index=[time, region], unit="degreeC")

    #impact Parameters
    rcons_per_cap_MarketRemainConsumption = Parameter(index=[time, region], unit = "")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, region], unit = "")

    SAVE_savingsrate = Parameter(unit= "%")
    WINCF_weightsfactor =Parameter(index=[region], unit="")
    W_NonImpactsatCalibrationTemp =Parameter()
    ipow_NonMarketImpactFxnExponent =Parameter()
    iben_NonMarketInitialBenefit=Parameter()
    tcal_CalibrationTemp = Parameter()
    GDP_per_cap_focus_0_FocusRegionEU = Parameter()
    isat_0_InitialImpactFxnSaturation= Parameter()

    #impact variables
    isatg_impactfxnsaturation = Variable()
    rcons_per_cap_NonMarketRemainConsumption = Variable(index=[time, region], unit = "")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, region], unit = "")
    iref_ImpactatReferenceGDPperCap=Variable(index=[time, region])
    igdp_ImpactatActualGDPperCap=Variable(index=[time, region])
    isat_ImpactinclSaturationandAdaptation= Variable(index=[time,region])
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,region])
end

function run_timestep(s::NonMarketDamages, t::Int64)
    v = s.Variables
    p = s.Parameters
    d = s.Dimensions

    for r in d.region
        #calculate tolerability
        if (p.y_year[t] - p.pstart_startdateofadaptpolicyNM[r]) < 0
            v.atl_adjustedtolerableleveloftemprise[t,r]= 0
        elseif ((p.y_year[t]-p.pstart_startdateofadaptpolicyNM[r])/p.pyears_yearstilfulleffectNM[r])<1.
            v.atl_adjustedtolerableleveloftemprise[t,r]=
                ((p.y_year[t]-p.pstart_startdateofadaptpolicyNM[r])/p.pyears_yearstilfulleffectNM[r]) *
                p.plateau_increaseintolerableplateaufromadaptationNM[r]
        else
            p.plateau_increaseintolerableplateaufromadaptationNM[r]
        end

        if (p.y_year[t]- p.istart_startdateNM[r]) < 0
            v.imp_actualreduction[t,r] = 0
        elseif ((p.y_year[t]-p.istart_startdateNM[r])/p.iyears_yearstilfulleffectNM[r]) < 1
            v.imp_actualreduction[t,r] =
                (p.y_year[t]-p.istart_startdateNM[r])/p.iyears_yearstilfulleffectNM[r]*
                p.impred_eventualpercentreductionNM[r]
        else
            v.imp_actualreduction[t,r] = p.impred_eventualpercentreductionNM[r]
        end

        if (p.rt_realizedtemperature[t,r]-v.atl_adjustedtolerableleveloftemprise[t,r]) < 0
            v.i_regionalimpact[t,r] = 0
        else
            v.i_regionalimpact[t,r] = p.rt_realizedtemperature[t,r]-v.atl_adjustedtolerableleveloftemprise[t,r]
        end

        v.iref_ImpactatReferenceGDPperCap[t,r]= p.WINCF_weightsfactor[r]*((p.W_NonImpactsatCalibrationTemp + p.iben_NonMarketInitialBenefit * p.tcal_CalibrationTemp)*
            (v.i_regionalimpact[t,r]/p.tcal_CalibrationTemp)^p.ipow_NonMarketImpactFxnExponent - v.i_regionalimpact[t,r] * p.iben_NonMarketInitialBenefit)

        v.igdp_ImpactatActualGDPperCap[t,r]= v.iref_ImpactatReferenceGDPperCap[t,r]*
            (p.rgdp_per_cap_MarketRemainGDP[t,r]/p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_NonMarketImpactFxnExponent

        v.isatg_impactfxnsaturation= p.isat_0_InitialImpactFxnSaturation * (1 - p.SAVE_savingsrate/100)

        if v.igdp_ImpactatActualGDPperCap[t,r] < v.isatg_impactfxnsaturation
            v.isat_ImpactinclSaturationandAdaptation[t,r] = v.igdp_ImpactatActualGDPperCap[t,r]
        elseif v.i_regionalimpact[t,r] < p.impmax_maxtempriseforadaptpolicyNM[r]
            v.isat_ImpactinclSaturationandAdaptation[t,r] = v.isatg_impactfxnsaturation+
                ((100-p.SAVE_savingsrate)-v.isatg_impactfxnsaturation)*
                ((v.igdp_ImpactatActualGDPperCap[t,r]-v.isatg_impactfxnsaturation)/
                (((100-p.SAVE_savingsrate)-v.isatg_impactfxnsaturation)+
                (v.igdp_ImpactatActualGDPperCap[t,r]*
                v.isatg_impactfxnsaturation)))*(1-v.imp_actualreduction/100)
        else
            v.isat_ImpactinclSaturationandAdaptation[t,r] = v.isatg_impactfxnsaturation+
                ((100-p.SAVE_savingsrate)-v.isatg_impactfxnsaturation) *
                ((v.igdp_ImpactatActualGDPperCap[t,r]-v.isatg_impactfxnsaturation)/
                (((100-p.SAVE_savingsrate)-v.isatg_impactfxnsaturation)+
                (v.igdp_ImpactatActualGDPperCap[t,r] * v.isatg_impactfxnsaturation))) *
                (1-(v.imp_actualreduction[t,r]/100)* p.impmax_maxtempriseforadaptpolicyNM[r] /
                v.i_regionalimpact[t,r])
        end

        v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptation[t,r]/100)*p.rgdp_per_cap_MarketRemainGDP[t,r]
        v.rcons_per_cap_NonMarketRemainConsumption[t,r] = p.rcons_per_cap_MarketRemainConsumption[t,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r]
        v.rgdp_per_cap_NonMarketRemainGDP[t,r] = v.rcons_per_cap_NonMarketRemainConsumption[t,r]/(1-p.SAVE_savingsrate/100)
    end
end

function addnonmarketdamages(model::Model)
    nonmarketdamagescomp = addcomponent(model, NonMarketDamages)

    nonmarketdamagescomp[:tcal_CalibrationTemp]= 2.5
    nonmarketdamagescomp[:isat_0_InitialImpactFxnSaturation]= .5
    nonmarketdamagescomp[:W_NonImpactsatCalibrationTemp] = .53
    nonmarketdamagescomp[:iben_NonMarketInitialBenefit] = .08
    nonmarketdamagescomp[:ipow_NonMarketImpactFxnExponent] = 2.17
    nonmarketdamagescomp[:SAVE_savingsrate]= 15.
    nonmarketdamagescomp[:GDP_per_cap_focus_0_FocusRegionEU]= (1.39*10^7)/496

    return nonmarketdamagescomp
end
