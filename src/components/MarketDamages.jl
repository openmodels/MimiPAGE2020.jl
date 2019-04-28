@defcomp MarketDamages begin
    region = Index()
    y_year = Parameter(index=[time], unit="year")

    #incoming parameters from Climate
    rtl_realizedtemperature = Parameter(index=[time, region], unit="degreeC")

    #tolerability variables
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC") # not required, adaptation is implicit for Burke damages
    imp_actualreduction = Parameter(index=[time, region], unit= "%") # not required, adaptation is implicit for Burke damages
    i_regionalimpact = Variable(index=[time, region], unit="degreeC")

    #impact Parameters
    rcons_per_cap_SLRRemainConsumption = Parameter(index=[time, region], unit = "\$/person")
    rgdp_per_cap_SLRRemainGDP = Parameter(index=[time, region], unit = "\$/person")

    save_savingsrate = Parameter(unit= "%", default=15.)
    wincf_weightsfactor =Parameter(index=[region], unit="")
    W_MarketImpactsatCalibrationTemp =Parameter(unit="%GDP", default=0.0) # not required for Burke damages
    ipow_MarketIncomeFxnExponent =Parameter(default=0.0)
    iben_MarketInitialBenefit=Parameter(default=0.0) # not required for Burke damages
    tcal_CalibrationTemp = Parameter(default=3.)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(default=34298.93698672955)

    # added impact parameters for Burke damage function
    rtl_abs_0_realizedabstemperature = Parameter(index = [region]) # 1979-2005 means, Yumashev et al. 2019 Supplementary Table 16, table in /data directory
    rtl_0_realizedtemperature = Parameter(index = [region]) # temperature change between PAGE base year temperature and rtl_abs_0 (?)
    impf_coeff_lin = Parameter(default = -0.00829990966469437) # rescaled coefficients from Burke
    impf_coeff_quadr = Parameter(default = -0.000500003403703578)
    tcal_burke = Parameter(default = 21.) # calibration temperature for the impact function
    i_burke_regionalimpact = Variable(index = [time, region], unit = "degreeC") # alternative version to i_regionalimpact
    i1log_impactlogchange = Variable(index = [time, region])
    nlag_burke = Parameter(default = 1.) # Yumashev et al. (2019) allow for one or two lags

    #impact variables
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_MarketRemainConsumption = Variable(index=[time, region], unit = "\$/person")
    rgdp_per_cap_MarketRemainGDP = Variable(index=[time, region], unit = "\$/person")
    iref_ImpactatReferenceGDPperCap=Variable(index=[time, region])
    igdp_ImpactatActualGDPperCap=Variable(index=[time, region])
    impmax_maxtempriseforadaptpolicyM = Parameter(index=[region], unit= "degreeC")

    isat_ImpactinclSaturationandAdaptation= Variable(index=[time,region])
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,region])
    pow_MarketImpactExponent=Parameter(unit="", default=2.1666666666666665) # not required for Burke damages

    # TO-DO:
    # 1) get absolute baseline temperatures at full precision (currently only extracted from supplementary info from Yumashev et al. 2019)
    # 2) connect the rlt_0 and rtl_abs_0 parameters to the component
    # 3) conduct test runs
    # 3) consider dropping the intermediate variable i1log and instead computing iref right away
    # 4) change the way previous years are included for growth effect analysis

    function run_timestep(p, v, d, t)

        for r in d.region
            # calculate the regional temperature impact relative to baseline year and add it to baseline absolute value
            v.i_burke_regionalimpact[t,r] = (p.rtl_realizedtemperature[t,r] - p.rtl_0_realizedtemperature[r]) + p.rtl_abs_0_realizedabstemperature[r]

            #calculate tolerability
#            if (p.rtl_realizedtemperature[t,r]-p.atl_adjustedtolerableleveloftemprise[t,r]) < 0    # adaptation is implicit for Burke damages
#                v.i_regionalimpact[t,r] = 0
#            else
#                v.i_regionalimpact[t,r] = p.rtl_realizedtemperature[t,r]-p.atl_adjustedtolerableleveloftemprise[t,r]
#            end


            # calculate the log change, depending on the number of lags specified
            v.i1log_impactlogchange[t,r] = p.nlag_burke * (p.impf_coeff_lin  * (v.i_burke_regionalimpact[t,r] - p.rtl_abs_0_realizedabstemperature[r]) +
                                p.impf_coeff_quadr * ((v.i_burke_regionalimpact[t,r] - p.tcal_burke)^2 -
                                                      (p.rtl_abs_0_realizedabstemperature[r] - p.tcal_burke)^2))

            # calculate the impact at focus region GDP p.c.
            v.iref_ImpactatReferenceGDPperCap[t,r] = 100 * p.wincf_weightsfactor[r] * (1 - exp(v.i1log_impactlogchange[t,r]))


#            v.iref_ImpactatReferenceGDPperCap[t,r]= p.wincf_weightsfactor[r]*((p.W_MarketImpactsatCalibrationTemp + p.iben_MarketInitialBenefit * p.tcal_CalibrationTemp)*  # old impact function for PAGE09
#                (v.i_regionalimpact[t,r]/p.tcal_CalibrationTemp)^p.pow_MarketImpactExponent - v.i_regionalimpact[t,r] * p.iben_MarketInitialBenefit)

            # calculate impacts at actual GDP
            v.igdp_ImpactatActualGDPperCap[t,r]= v.iref_ImpactatReferenceGDPperCap[t,r]*
                (p.rgdp_per_cap_SLRRemainGDP[t,r]/p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_MarketIncomeFxnExponent

            # send impacts down a logistic path if saturation threshold is exceeded
            if v.igdp_ImpactatActualGDPperCap[t,r] < p.isatg_impactfxnsaturation
                v.isat_ImpactinclSaturationandAdaptation[t,r] = v.igdp_ImpactatActualGDPperCap[t,r]
            else
                v.isat_ImpactinclSaturationandAdaptation[t,r] = p.isatg_impactfxnsaturation+
                    ((100-p.save_savingsrate)-p.isatg_impactfxnsaturation)*
                    ((v.igdp_ImpactatActualGDPperCap[t,r]-p.isatg_impactfxnsaturation)/
                    (((100-p.save_savingsrate)-p.isatg_impactfxnsaturation)+
                    (v.igdp_ImpactatActualGDPperCap[t,r]-
                    p.isatg_impactfxnsaturation)))
                end

            # let adaptation decrease impacts
#            if v.i_regionalimpact[t,r] < p.impmax_maxtempriseforadaptpolicyM[r]  adaptation is implicit for Burke damages
#                v.isat_ImpactinclSaturationandAdaptation[t,r]=v.isat_ImpactinclSaturationandAdaptation[t,r]*(1-p.imp_actualreduction[t,r]/100)
#            else
#                v.isat_ImpactinclSaturationandAdaptation[t,r] = v.isat_ImpactinclSaturationandAdaptation[t,r] *
#                    (1-(p.imp_actualreduction[t,r]/100)* p.impmax_maxtempriseforadaptpolicyM[r] /
#                    v.i_regionalimpact[t,r])
#            end

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptation[t,r]/100)*p.rgdp_per_cap_SLRRemainGDP[t,r]
            v.rcons_per_cap_MarketRemainConsumption[t,r] = p.rcons_per_cap_SLRRemainConsumption[t,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r]
            v.rgdp_per_cap_MarketRemainGDP[t,r] = v.rcons_per_cap_MarketRemainConsumption[t,r]/(1-p.save_savingsrate/100)
        end

    end
end

# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.

function addmarketdamages(model::Model)
    marketdamagescomp = add_comp!(model, MarketDamages)
    marketdamagescomp[:impmax_maxtempriseforadaptpolicyM] = readpagedata(model, "data/impmax_economic.csv")

    return marketdamagescomp
end
