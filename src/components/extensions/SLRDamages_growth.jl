@defcomp SLRDamages begin
    region = Index()

    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")

    # incoming parameters from SeaLevelRise
    s_sealevel = Parameter(index=[time], unit="m")
    # incoming parameters to calculate consumption per capita after Costs
    cons_percap_consumption = Parameter(index=[time, region], unit="\$/person")
    cons_percap_consumption_0 = Parameter(index=[region], unit="\$/person")
    tct_per_cap_totalcostspercap = Parameter(index=[time,region], unit="\$/person")
    act_percap_adaptationcosts = Parameter(index=[time, region], unit="\$/person")

    # component parameters
    impmax_maxSLRforadaptpolicySLR = Parameter(index=[region], unit="m")

    save_savingsrate = Parameter(unit="%", default=15.00) # pp33 PAGE09 documentation, "savings rate".
    wincf_weightsfactor_sea = Parameter(index=[region], unit="")
    W_SatCalibrationSLR = Parameter(default=1.0) # pp33 PAGE09 documentation, "Sea level impact at calibration sea level rise"
    ipow_SLRIncomeFxnExponent = Parameter(default=-0.30)
    pow_SLRImpactFxnExponent = Parameter(default=0.7333333333333334)
    iben_SLRInitialBenefit = Parameter(default=0.00)
    scal_calibrationSLR = Parameter(default=0.5)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)

    # component variables
    cons_percap_aftercosts = Variable(index=[time, region], unit="\$/person")
    gdp_percap_aftercosts = Variable(index=[time, region], unit="\$/person")

    atl_adjustedtolerablelevelofsealevelrise = Parameter(index=[time,region], unit="m") # meter
    imp_actualreductionSLR = Parameter(index=[time, region], unit="%")
    i_regionalimpactSLR = Variable(index=[time, region], unit="m")

    iref_ImpactatReferenceGDPperCapSLR = Variable(index=[time, region])
    igdp_ImpactatActualGDPperCapSLR = Variable(index=[time, region])

    isatg_impactfxnsaturation = Parameter(unit="unitless")
    isat_ImpactinclSaturationandAdaptationSLR = Variable(index=[time,region])
    isat_per_cap_SLRImpactperCapinclSaturationandAdaptation = Variable(index=[time, region], unit="\$/person")

    rcons_per_cap_SLRRemainConsumption = Variable(index=[time, region], unit="\$/person") # include?
    rgdp_per_cap_SLRRemainGDP = Variable(index=[time, region], unit="\$/person")

    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    # new parameters for convergence boundary system
    use_convergence =                           Parameter(unit="none", default=1.)
    cbabs_pcconsumptionbound =                  Parameter(unit="\$/person", default=740.65)
    cbabsn_pcconsumptionbound_neighbourhood =   Parameter(unit="\$/person")
    cbaux1_pcconsumptionbound_auxiliary1 =      Parameter(unit="none")
    cbaux2_pcconsumptionbound_auxiliary2 =      Parameter(unit="none")
    cons_percap_consumption_noconvergence =     Parameter(index=[time, region], unit="\$/person")
    ###############################################

    function run_timestep(p, v, d, t)

    for r in d.region
        v.cons_percap_aftercosts[t, r] = p.cons_percap_consumption[t, r] - p.tct_per_cap_totalcostspercap[t, r] - p.act_percap_adaptationcosts[t, r]

            # apply the boundary condition if consumption minus adaptation and mitigation costs drops below the threshold
        if p.use_convergence == 1. && (v.cons_percap_aftercosts[t, r] < p.cbabsn_pcconsumptionbound_neighbourhood)
            v.cons_percap_aftercosts[t, r] = p.cbabsn_pcconsumptionbound_neighbourhood - 0.5 * p.cbaux1_pcconsumptionbound_auxiliary1 +
                                    p.cbaux1_pcconsumptionbound_auxiliary1 * exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                            (p.cons_percap_consumption_noconvergence[t,r] - p.tct_per_cap_totalcostspercap[t, r] - p.act_percap_adaptationcosts[t, r] - p.cbabsn_pcconsumptionbound_neighbourhood)) /
                                                                        (1 + exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                (p.cons_percap_consumption_noconvergence[t,r] - p.tct_per_cap_totalcostspercap[t, r] - p.act_percap_adaptationcosts[t, r] - p.cbabsn_pcconsumptionbound_neighbourhood)))
        elseif p.use_convergence != 1. && (v.cons_percap_aftercosts[t, r] < p.cbabs_pcconsumptionbound)
                v.cons_percap_aftercosts[t, r] = p.cbabs_pcconsumptionbound
        end

        v.gdp_percap_aftercosts[t,r] = v.cons_percap_aftercosts[t, r] / (1 - p.save_savingsrate / 100)

        if (p.s_sealevel[t] - p.atl_adjustedtolerablelevelofsealevelrise[t,r]) < 0
            v.i_regionalimpactSLR[t,r] = 0
        else
            v.i_regionalimpactSLR[t,r] = p.s_sealevel[t] - p.atl_adjustedtolerablelevelofsealevelrise[t,r]
        end

        v.iref_ImpactatReferenceGDPperCapSLR[t,r] = p.wincf_weightsfactor_sea[r] * ((p.W_SatCalibrationSLR + p.iben_SLRInitialBenefit * p.scal_calibrationSLR) *
                (v.i_regionalimpactSLR[t,r] / p.scal_calibrationSLR)^p.pow_SLRImpactFxnExponent - v.i_regionalimpactSLR[t,r] * p.iben_SLRInitialBenefit)

        v.igdp_ImpactatActualGDPperCapSLR[t,r] = v.iref_ImpactatReferenceGDPperCapSLR[t,r] *
                    (v.gdp_percap_aftercosts[t,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_SLRIncomeFxnExponent

        if v.igdp_ImpactatActualGDPperCapSLR[t,r] < p.isatg_impactfxnsaturation
            v.isat_ImpactinclSaturationandAdaptationSLR[t,r] = v.igdp_ImpactatActualGDPperCapSLR[t,r]
        else
            v.isat_ImpactinclSaturationandAdaptationSLR[t,r] = p.isatg_impactfxnsaturation +
                    ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
                    ((v.igdp_ImpactatActualGDPperCapSLR[t,r] - p.isatg_impactfxnsaturation) /
                    (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
                    (v.igdp_ImpactatActualGDPperCapSLR[t,r] - p.isatg_impactfxnsaturation)))
        end
        if v.i_regionalimpactSLR[t,r] < p.impmax_maxSLRforadaptpolicySLR[r]
            v.isat_ImpactinclSaturationandAdaptationSLR[t,r] = v.isat_ImpactinclSaturationandAdaptationSLR[t,r] * (1 - p.imp_actualreductionSLR[t,r] / 100)
        else
            v.isat_ImpactinclSaturationandAdaptationSLR[t,r] = v.isat_ImpactinclSaturationandAdaptationSLR[t,r] * (1 - (p.imp_actualreductionSLR[t,r] / 100) * p.impmax_maxSLRforadaptpolicySLR[r] /
                    v.i_regionalimpactSLR[t,r])
        end

        v.isat_per_cap_SLRImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptationSLR[t,r] / 100) * v.gdp_percap_aftercosts[t,r]
        v.rcons_per_cap_SLRRemainConsumption[t,r] = v.cons_percap_aftercosts[t,r] - v.isat_per_cap_SLRImpactperCapinclSaturationandAdaptation[t,r]
        v.rgdp_per_cap_SLRRemainGDP[t,r] = v.rcons_per_cap_SLRRemainConsumption[t,r] / (1 - p.save_savingsrate / 100)

    end

end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addslrdamages(model::Model)
    SLRDamagescomp = add_comp!(model, SLRDamages)

    SLRDamagescomp[:wincf_weightsfactor_sea] = readpagedata(model, "data/wincf_weightsfactor_sea.csv")
    SLRDamagescomp[:impmax_maxSLRforadaptpolicySLR] = readpagedata(model, "data/impmax_sealevel.csv")

    return SLRDamagescomp
end
