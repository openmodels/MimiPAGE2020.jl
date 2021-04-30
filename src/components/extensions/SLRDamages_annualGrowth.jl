function interpolate_parameters_slrdamages(p, v, d, t)
    # interpolation of parameters, see notes in run_timestep for why these parameters
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - 2015
            fraction_timestep = frac / (gettime(t) - 2015)
            for r in d.region

                if use_linear || use_logburke || use_logpopulation
                    # linear
                    v.s_sealevel_ann[yr] = p.s_sealevel[t] * fraction_timestep + p.s0_initialSL * (1 - fraction_timestep)
                    v.tct_per_cap_totalcostspercap_ann[yr, r] = p.tct_per_cap_totalcostspercap[t, r] * fraction_timestep
                elseif use_logwherepossible
                    # log
                    v.s_sealevel_ann[yr] = p.s_sealevel[t]^fraction_timestep * p.s0_initialSL^(1 - fraction_timestep)
                    # linear (because tct is zero at the start of the model run)
                    v.tct_per_cap_totalcostspercap_ann[yr, r] = p.tct_per_cap_totalcostspercap[t, r] * fraction_timestep
                end

            end
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - gettime(t - 1)
            fraction_timestep = frac / ((gettime(t)) - (gettime(t - 1)))

            for r in d.region
                if use_linear || use_logburke || use_logpopulation
                    # linear
                    v.s_sealevel_ann[yr] = p.s_sealevel[t] * fraction_timestep + p.s_sealevel[t - 1] * (1 - fraction_timestep)
                    v.tct_per_cap_totalcostspercap_ann[yr, r] = p.tct_per_cap_totalcostspercap[t, r] * fraction_timestep + p.tct_per_cap_totalcostspercap[t - 1, r] * (1 - fraction_timestep)
                elseif use_logwherepossible
                    # log
                    v.s_sealevel_ann[yr] = p.s_sealevel[t]^fraction_timestep * p.s_sealevel[t - 1]^(1 - fraction_timestep)
                    # linear (because tct can turn negative)
                    v.tct_per_cap_totalcostspercap_ann[yr, r] = p.tct_per_cap_totalcostspercap[t, r] * fraction_timestep + p.tct_per_cap_totalcostspercap[t - 1, r] * (1 - fraction_timestep)
                else
                    error("NO INTERPOLATION METHOD SELECTED! Specify linear or logarithmic interpolation.")
                end

            end
        end
    end
end

function calc_SLRDamages(p, v, d, t, annual_year)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    for r in d.region
        v.cons_percap_aftercosts_ann[yr, r] = p.cons_percap_consumption_ann[yr, r] - v.tct_per_cap_totalcostspercap_ann[yr, r] - p.act_percap_adaptationcosts_ann[yr, r]

        # apply the boundary condition if consumption minus adaptation and mitigation costs drops below the threshold
        if p.use_convergence == 1. && (v.cons_percap_aftercosts_ann[yr, r] < p.cbabsn_pcconsumptionbound_neighbourhood)
            v.cons_percap_aftercosts_ann[yr, r] = p.cbabsn_pcconsumptionbound_neighbourhood - 0.5 * p.cbaux1_pcconsumptionbound_auxiliary1 +
                                p.cbaux1_pcconsumptionbound_auxiliary1 * exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                        (p.cons_percap_consumption_noconvergence_ann[yr,r] - v.tct_per_cap_totalcostspercap_ann[yr, r] - p.act_percap_adaptationcosts_ann[yr, r] - p.cbabsn_pcconsumptionbound_neighbourhood)) /
                                                                    (1 + exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                            (p.cons_percap_consumption_noconvergence_ann[yr,r] - v.tct_per_cap_totalcostspercap_ann[yr, r] - p.act_percap_adaptationcosts_ann[yr, r] - p.cbabsn_pcconsumptionbound_neighbourhood)))
        elseif p.use_convergence != 1. && (v.cons_percap_aftercosts_ann[yr, r] < p.cbabs_pcconsumptionbound)
            v.cons_percap_aftercosts_ann[yr, r] = p.cbabs_pcconsumptionbound
        end

        v.gdp_percap_aftercosts_ann[yr,r] = v.cons_percap_aftercosts_ann[yr, r] / (1 - p.save_savingsrate / 100)

        if (v.s_sealevel_ann[yr] - p.atl_adjustedtolerablelevelofsealevelrise_ann[yr,r]) < 0
            v.i_regionalimpactSLR_ann[yr,r] = 0
        else
            v.i_regionalimpactSLR_ann[yr,r] = v.s_sealevel_ann[yr] - p.atl_adjustedtolerablelevelofsealevelrise_ann[yr,r]
        end

        v.iref_ImpactatReferenceGDPperCapSLR_ann[yr,r] = p.wincf_weightsfactor_sea[r] * ((p.W_SatCalibrationSLR + p.iben_SLRInitialBenefit * p.scal_calibrationSLR) *
            (v.i_regionalimpactSLR_ann[yr,r] / p.scal_calibrationSLR)^p.pow_SLRImpactFxnExponent - v.i_regionalimpactSLR_ann[yr,r] * p.iben_SLRInitialBenefit)

        v.igdp_ImpactatActualGDPperCapSLR_ann[yr,r] = v.iref_ImpactatReferenceGDPperCapSLR_ann[yr,r] *
                (v.gdp_percap_aftercosts_ann[yr,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_SLRIncomeFxnExponent

        if v.igdp_ImpactatActualGDPperCapSLR_ann[yr,r] < p.isatg_impactfxnsaturation
            v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] = v.igdp_ImpactatActualGDPperCapSLR_ann[yr,r]
        else
            v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] = p.isatg_impactfxnsaturation +
                ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
                ((v.igdp_ImpactatActualGDPperCapSLR_ann[yr,r] - p.isatg_impactfxnsaturation) /
                (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
                (v.igdp_ImpactatActualGDPperCapSLR_ann[yr,r] - p.isatg_impactfxnsaturation)))
        end
        if v.i_regionalimpactSLR_ann[yr,r] < p.impmax_maxSLRforadaptpolicySLR[r]
            v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] = v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] * (1 - p.imp_actualreductionSLR_ann[yr,r] / 100)
        else
            v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] = v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] * (1 - (p.imp_actualreductionSLR_ann[yr,r] / 100) * p.impmax_maxSLRforadaptpolicySLR[r] /
                v.i_regionalimpactSLR_ann[yr,r])
        end

        v.isat_per_cap_SLRImpactperCapinclSaturationandAdaptation_ann[yr,r] = (v.isat_ImpactinclSaturationandAdaptationSLR_ann[yr,r] / 100) * v.gdp_percap_aftercosts_ann[yr,r]
        v.rcons_per_cap_SLRRemainConsumption_ann[yr,r] = v.cons_percap_aftercosts_ann[yr,r] - v.isat_per_cap_SLRImpactperCapinclSaturationandAdaptation_ann[yr,r]
        v.rgdp_per_cap_SLRRemainGDP_ann[yr,r] = v.rcons_per_cap_SLRRemainConsumption_ann[yr,r] / (1 - p.save_savingsrate / 100)

    end

end



@defcomp SLRDamages begin
    region = Index()
    year = Index()

    y_year = Parameter(index=[time], unit="year")
    y_year_ann = Parameter(index=[year], unit="year")
    y_year_0 = Parameter(unit="year")

    # incoming parameters from SeaLevelRise
    s_sealevel = Parameter(index=[time], unit="m")
    s0_initialSL = Parameter(unit="m", default=0.18999999999999997)               # mode initial sea level, from PAGE-ICE
    s_sealevel_ann = Variable(index=[year], unit="m")                                                                                   # interpolate (SeaLevelRise)
    # incoming parameters to calculate consumption per capita after Costs
    cons_percap_consumption = Parameter(index=[time, region], unit="\$/person")
    cons_percap_consumption_ann = Parameter(index=[year, region], unit="\$/person")
    cons_percap_consumption_0 = Parameter(index=[region], unit="\$/person")
    tct_per_cap_totalcostspercap = Parameter(index=[time,region], unit="\$/person")
    tct_per_cap_totalcostspercap_ann = Variable(index=[year,region], unit="\$/person")                                                 # interpolate (TotalAbatement)
    act_percap_adaptationcosts = Parameter(index=[time, region], unit="\$/person")
    act_percap_adaptationcosts_ann = Parameter(index=[year, region], unit="\$/person")

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
    cons_percap_aftercosts_ann = Variable(index=[year, region], unit="\$/person")
    gdp_percap_aftercosts = Variable(index=[time, region], unit="\$/person")
    gdp_percap_aftercosts_ann = Variable(index=[year, region], unit="\$/person")

    atl_adjustedtolerablelevelofsealevelrise = Parameter(index=[time,region], unit="m") # meter
    atl_adjustedtolerablelevelofsealevelrise_ann = Parameter(index=[year,region], unit="m") # meter
    imp_actualreductionSLR = Parameter(index=[time, region], unit="%")
    imp_actualreductionSLR_ann = Parameter(index=[year, region], unit="%")
    i_regionalimpactSLR = Variable(index=[time, region], unit="m")
    i_regionalimpactSLR_ann = Variable(index=[year, region], unit="m")

    iref_ImpactatReferenceGDPperCapSLR = Variable(index=[time, region])
    iref_ImpactatReferenceGDPperCapSLR_ann = Variable(index=[year, region])
    igdp_ImpactatActualGDPperCapSLR = Variable(index=[time, region])
    igdp_ImpactatActualGDPperCapSLR_ann = Variable(index=[year, region])

    isatg_impactfxnsaturation = Parameter(unit="unitless")
    isat_ImpactinclSaturationandAdaptationSLR = Variable(index=[time,region])
    isat_ImpactinclSaturationandAdaptationSLR_ann = Variable(index=[year,region])
    isat_per_cap_SLRImpactperCapinclSaturationandAdaptation = Variable(index=[time, region], unit="\$/person")
    isat_per_cap_SLRImpactperCapinclSaturationandAdaptation_ann = Variable(index=[year, region], unit="\$/person")

    rcons_per_cap_SLRRemainConsumption = Variable(index=[time, region], unit="\$/person") # include?
    rcons_per_cap_SLRRemainConsumption_ann = Variable(index=[year, region], unit="\$/person") # include?
    rgdp_per_cap_SLRRemainGDP = Variable(index=[time, region], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP_ann = Variable(index=[year, region], unit="\$/person")

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
    cons_percap_consumption_noconvergence_ann = Parameter(index=[year, region], unit="\$/person")
    ###############################################

    function run_timestep(p, v, d, t)

    interpolate_parameters_slrdamages(p, v, d, t)

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

        # calculate  for this specific year
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            calc_SLRDamages(p, v, d, t, annual_year)
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            calc_SLRDamages(p, v, d, t, annual_year)
        end
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
