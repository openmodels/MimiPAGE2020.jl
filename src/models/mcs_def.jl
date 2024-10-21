import Mimi.add_RV!, Mimi.add_transform!

function getsim()
    mcs = @defsim begin

        ## NOTE: some assignment to global variables can probably be avoided now
        ## with new treatment of shared and unshared parameters, but this will
        ## all work for now!

        ############################################################################
        # Define random variables (RVs) - for UNSHARED parameters
        ############################################################################

        # each component should have the same value for its save_savingsrate,
        # so we use an RV here because in the model this is not an explicitly
        # shared parameter, then assign to components
        rv(RV_save_savingsrate) = TriangularDist(10, 20, 15)
        GDP.save_savingsrate = RV_save_savingsrate
        MarketDamagesBurke.save_savingsrate = RV_save_savingsrate
        NonMarketDamages.save_savingsrate = RV_save_savingsrate
        SLRDamages.save_savingsrate = RV_save_savingsrate

        # each component should have the same value for its tcal_CalibrationTemp
        # so we use an RV here because in the model this is not an explicitly
        # shared parameter, then assign to components
        rv(RV_tcal_CalibrationTemp) = TriangularDist(2.5, 3.5, 3.)
        NonMarketDamages.tcal_CalibrationTemp = RV_tcal_CalibrationTemp

        # each component should have the same value for its q0propmult_cutbacksatnegativecostinfinalyear
        # so we use an RV here because in the model this is not an explicitly
        # shared parameter, then assign to components
        q0propmult_cutbacksatnegativecostinfinalyear = TriangularDist(0.3, 1.2, 0.7)

        # CO2cycle
        CO2Cycle.air_CO2fractioninatm = TriangularDist(57, 67, 62)
        CO2Cycle.res_CO2atmlifetime = TriangularDist(50, 100, 70)
        # CO2Cycle.ccf_CO2feedback = TriangularDist(0, 0, 0) # only usable if lb <> ub
        CO2Cycle.ccfmax_maxCO2feedback = TriangularDist(10, 30, 20)
        CO2Cycle.stay_fractionCO2emissionsinatm = TriangularDist(0.25, 0.35, 0.3)
        CO2Cycle.ce_0_basecumCO2emissions = TriangularDist(1830000, 2240000, 2040000)
        CO2Cycle.a1_percentco2oceanlong = TriangularDist(4.3,	41.6, 23.0)
        CO2Cycle.a2_percentco2oceanshort = TriangularDist(23.1, 30.1, 26.6)
        CO2Cycle.a3_percentco2land = TriangularDist(11.4, 42.5, 27.0)
        CO2Cycle.t1_timeco2oceanlong = TriangularDist(248.9, 376.2, 312.5)
        CO2Cycle.t2_timeco2oceanshort = TriangularDist(25.9, 43.9, 34.9)
        CO2Cycle.t3_timeco2land = TriangularDist(2.8, 5.7, 4.3)
        CO2Cycle.rt_g0_baseglobaltemp = TriangularDist(0.903, 0.989, 0.946)

        # SiBCASA Permafrost
        PermafrostSiBCASA.perm_sib_af = TriangularDist(1.42609149897258, 2.32504747848815, 1.87556948873036)
        PermafrostSiBCASA.perm_sib_sens_c_co2 = TriangularDist(28191.1555428869, 35688.3253432574, 31939.7404430722)
        PermafrostSiBCASA.perm_sib_lag_c_co2 = TriangularDist(35.4926669856915, 87.8949041341782, 61.6937855599349)
        PermafrostSiBCASA.perm_sib_pow_c_co2 = TriangularDist(0.107020247715729, 0.410961185142816, 0.258990716429273)
        PermafrostSiBCASA.perm_sib_sens_c_ch4 = TriangularDist(1240.3553299183, 3348.11995329232, 2294.23764160531)
        PermafrostSiBCASA.perm_sib_lag_c_ch4 = TriangularDist(75.1943160023131, 337.382510123922, 206.288413063117)
        PermafrostSiBCASA.perm_sib_pow_c_ch4 = TriangularDist(-0.108779283732708, 0.610889007954489, 0.25105486211089)

        # JULES Permafrost
        PermafrostJULES.perm_jul_af = TriangularDist(1.70960411816136, 2.16221162526313, 1.93590787171224)
        PermafrostJULES.perm_jul_sens_c_co2 = TriangularDist(24726.8035695649, 99008.7553497378, 61867.7794596514)
        PermafrostJULES.perm_jul_lag_c_co2 = TriangularDist(252.558368389676, 834.674343162273, 543.616355775975)
        PermafrostJULES.perm_jul_pow_c_co2 = TriangularDist(-0.226045987062471, 1.14010750072118, 0.457030756829357)
        PermafrostJULES.perm_jul_ch4_co2_c_ratio = TriangularDist(2.77492291880781, 9.52902519167579, 6.04453870625663)

        # SulphateForcing
        SulphateForcing.d_sulphateforcingbase = TriangularDist(-0.8, -0.2, -0.4)
        SulphateForcing.ind_slopeSEforcing_indirect = TriangularDist(-0.8, 0, -0.4)

        # GlobalTemperature
        GlobalTemperature.frt_warminghalflife = TriangularDist(10, 55, 20)        # from PAGE-ICE v6.2 documentation
        GlobalTemperature.tcr_transientresponse = TriangularDist(0.8, 2.7, 1.8)   # from PAGE-ICE v6.2 documentation
        GlobalTemperature.alb_emulator_rand = TriangularDist(-1., 1., 0.)

        # RegionTemperature
        rv(prcile) = Uniform(0, 1)
        RegionTemperature_prcile = prcile

        # SeaLevelRise
        SeaLevelRise.s0_initialSL = TriangularDist(0.17, 0.21, 0.19)        # taken from PAGE-ICE v6.20 default
        SeaLevelRise.sltemp_SLtemprise = TriangularDist(0.7, 3., 1.5)       # median sensitivity to GMST changes
        SeaLevelRise.sla_SLbaselinerise = TriangularDist(0.5, 1.5, 1.)      # asymptote for pre-industrial
        SeaLevelRise.sltau_SLresponsetime = Gamma(16.0833333333333333, 24.) # fat-tailed distribution of time constant T_sl, sea level response time, from mode=362, mean = 386

        # RCPSSPScenario
        RCPSSPScenario_rateuniforms = Uniform(0, 1) # <-- Added after @defsim

        # GDP
        GDP.isat0_initialimpactfxnsaturation = TriangularDist(15, 25, 20)

        # MarketDamagesBurke
        rv(burkey_draw) = DiscreteUniform(1, 4000)
        MarketDamagesBurke_burkey_draw = burkey_draw
        MarketDamagesBurke.impf_coeff_lin = TriangularDist(-0.0139791885347898, -0.0026206307945989, -0.00829990966469437)
        MarketDamagesBurke.impf_coeff_quadr = TriangularDist(-0.000599999506482576, -0.000400007300924579, -0.000500003403703578)

        # NonMarketDamages
        NonMarketDamages.iben_NonMarketInitialBenefit = TriangularDist(0, .2, .05)
        NonMarketDamages.w_NonImpactsatCalibrationTemp = Normal(0.487 * 1.25 * 3*3, 0.182 * 1.25 * 3*3)
        NonMarketDamages.ipow_NonMarketIncomeFxnExponent = TriangularDist(-.2, .2, 0)

        # SLRDamages
        rv(RV_sealevelcost_draw) = DiscreteUniform(1, 100)
        SLRDamages_sealevelcost_draw = RV_sealevelcost_draw

        # Discontinuity
        Discontinuity.rand_discontinuity = Uniform(0, 1)
        Discontinuity.tdis_tolerabilitydisc = TriangularDist(1, 2, 1.5)
        Discontinuity.pdis_probability = TriangularDist(10, 30, 20)
        Discontinuity.wdis_gdplostdisc = TriangularDist(1, 5, 3)
        Discontinuity.ipow_incomeexponent = TriangularDist(-.3, 0, -.1)
        Discontinuity.distau_discontinuityexponent = TriangularDist(10, 30, 20)

        # CountryLevelNPV
        rv(pref_draw) = DiscreteUniform(1, 181)
        CountryLevelNPV.pref_draw = pref_draw

        # EquityWeighting
        EquityWeighting.civvalue_civilizationvalue = TriangularDist(1e10, 1e11, 5e10)
        EquityWeighting.pref_draw = pref_draw

        # RFFSPScenario
        rv(rffsp_draw) = DiscreteUniform(1, 9400)
        RFFSPScenario_rffsp_draw = rffsp_draw

        ############################################################################
        # Define random variables (RVs) - for SHARED parameters
        ############################################################################

        # shared parameter linked to components: SLRDamages, Discontinuity (weights
        # for market and nonmarket are non-stochastic and uniformly 1)
        wincf_weightsfactor_sea["USA"] = TriangularDist(.6, 1, .8)
        wincf_weightsfactor_sea["OECD"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["USSR"] = TriangularDist(.2, .6, .4)
        wincf_weightsfactor_sea["China"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["SEAsia"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["Africa"] = TriangularDist(.4, .8, .6)
        wincf_weightsfactor_sea["LatAmerica"] = TriangularDist(.4, .8, .6)

        # shared parameter linked to components: AdaptationCosts, AbatementCosts
        automult_autonomoustechchange = TriangularDist(0.5, 0.8, 0.65)

        # the following variables need to be set, but set the same in all 4 abatement cost components
        # note that for these regional variables, the first region is the focus region (EU), which is set in the preceding code, and so is always one for these variables

        emitf_uncertaintyinBAUemissfactor["USA"] = TriangularDist(0.8, 1.2, 1.0)
        emitf_uncertaintyinBAUemissfactor["OECD"] = TriangularDist(0.8, 1.2, 1.0)
        emitf_uncertaintyinBAUemissfactor["USSR"] = TriangularDist(0.65, 1.35, 1.0)
        emitf_uncertaintyinBAUemissfactor["China"] = TriangularDist(0.5, 1.5, 1.0)
        emitf_uncertaintyinBAUemissfactor["SEAsia"] = TriangularDist(0.5, 1.5, 1.0)
        emitf_uncertaintyinBAUemissfactor["Africa"] = TriangularDist(0.5, 1.5, 1.0)
        emitf_uncertaintyinBAUemissfactor["LatAmerica"] = TriangularDist(0.5, 1.5, 1.0)

        q0f_negativecostpercentagefactor["USA"] = TriangularDist(0.75, 1.5, 1.0)
        q0f_negativecostpercentagefactor["OECD"] = TriangularDist(0.75, 1.25, 1.0)
        q0f_negativecostpercentagefactor["USSR"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["China"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["SEAsia"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["Africa"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["LatAmerica"] = TriangularDist(0.4, 1.0, 0.7)

        cmaxf_maxcostfactor["USA"] = TriangularDist(0.8, 1.2, 1.0)
        cmaxf_maxcostfactor["OECD"] = TriangularDist(1.0, 1.5, 1.2)
        cmaxf_maxcostfactor["USSR"] = TriangularDist(0.4, 1.0, 0.7)
        cmaxf_maxcostfactor["China"] = TriangularDist(0.8, 1.2, 1.0)
        cmaxf_maxcostfactor["SEAsia"] = TriangularDist(1, 1.5, 1.2)
        cmaxf_maxcostfactor["Africa"] = TriangularDist(1, 1.5, 1.2)
        cmaxf_maxcostfactor["LatAmerica"] = TriangularDist(0.4, 1.0, 0.7)

        cf_costregional["USA"] = TriangularDist(0.6, 1, 0.8)
        cf_costregional["OECD"] = TriangularDist(0.4, 1.2, 0.8)
        cf_costregional["USSR"] = TriangularDist(0.2, 0.6, 0.4)
        cf_costregional["China"] = TriangularDist(0.4, 1.2, 0.8)
        cf_costregional["SEAsia"] = TriangularDist(0.4, 1.2, 0.8)
        cf_costregional["Africa"] = TriangularDist(0.4, 0.8, 0.6)
        cf_costregional["LatAmerica"] = TriangularDist(0.4, 0.8, 0.6)

        # Others
        qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear = TriangularDist(1, 1.5, 1.3)
        c0mult_mostnegativecostinfinalyear = TriangularDist(0.5, 1.2, 0.8)
        curve_below_curvatureofMACcurvebelowzerocost = TriangularDist(0.25, 0.8, 0.45)
        curve_above_curvatureofMACcurveabovezerocost = TriangularDist(0.1, 0.7, 0.4)
        cross_experiencecrossoverratio = TriangularDist(0.1, 0.3, 0.2)
        learn_learningrate = TriangularDist(0.05, 0.35, 0.2)

        # NOTE: the below can probably be resolved into unique, unshared parameters with the same name
        # in the new Mimi paradigm of shared and unshared parameters, but for now this will
        # continue to work!

        # AbatementCosts
        rv(RV_mac_draw) = DiscreteUniform(1, 100)
        AbatementCostsCO2_mac_draw = RV_mac_draw

        AbatementCostParametersCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-67, 6.0, -30)
        AbatementCostParametersN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-20, 6.0, -7.0)
        AbatementCostParametersLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50, 50, 0)

        AbatementCostParametersCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        AbatementCostParametersN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        AbatementCostParametersLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)

        AbatementCostParametersCH4_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-8000, -1000, -4000)
        AbatementCostParametersN2O_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-15000, 0, -7000)
        AbatementCostParametersLin_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400, -100, -200)

        AbatementCostParametersCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35, 70, 50)
        AbatementCostParametersN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35, 70, 50)
        AbatementCostParametersLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60, 80, 70)

        AbatementCostParametersCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(3000, 10000, 6000)
        AbatementCostParametersN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(2000, 60000, 20000)
        AbatementCostParametersLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100, 600, 300)

        AbatementCostParametersCH4_ies_InitialExperienceStockofCutbacks = TriangularDist(1500, 2500, 2000)
        AbatementCostParametersN2O_ies_InitialExperienceStockofCutbacks = TriangularDist(30, 80, 50)
        AbatementCostParametersLin_ies_InitialExperienceStockofCutbacks = TriangularDist(1500, 2500, 2000)

        # AdaptationCosts
        AdaptiveCostsSeaLevel_sealevelcost_draw = RV_sealevelcost_draw

        AdaptiveCostsEconomic_cp_costplateau_eu = TriangularDist(0.005, 0.02, 0.01)
        AdaptiveCostsEconomic_ci_costimpact_eu = TriangularDist(0.001, 0.008, 0.003)
        AdaptiveCostsNonEconomic_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
        AdaptiveCostsNonEconomic_ci_costimpact_eu = TriangularDist(0.002, 0.01, 0.005)

        # CarbonPriceInfer
        CarbonPriceInfer_mac_draw = RV_mac_draw
        CarbonPriceInfer_baselineco2_uniforms = Uniform(0, 1) # <-- Added after @defsim

        ############################################################################
        # Indicate which parameters to save for each model run
        ############################################################################

        save(EquityWeighting.td_totaldiscountedimpacts,
             EquityWeighting.tpc_totalaggregatedcosts,
             EquityWeighting.tac_totaladaptationcosts,
             EquityWeighting.te_totaleffect,
             EquityWeighting.wit_percap_equityweightedimpact,
             EquityWeighting.eact_percap_weightedadaptationcosts,
             EquityWeighting.cons_percap_aftercosts, # without equity
             EquityWeighting.rcons_percap_dis, # without equity
             EquityWeighting.act_percap_adaptationcosts, # without equity
             CO2Cycle.c_CO2concentration,
             TotalForcing.ft_totalforcing,
             GlobalTemperature.rt_g_globaltemperature,
             GDP.cons_percap_consumption,
             Population.pop_population,
             SeaLevelRise.s_sealevel,
             SLRDamages.rgdp_per_cap_SLRRemainGDP,
             MarketDamagesBurke.rgdp_per_cap_MarketRemainGDP,
             NonMarketDamages.rgdp_per_cap_NonMarketRemainGDP,
             Discontinuity.rgdp_per_cap_NonMarketRemainGDP)

    end # de

    # for (ii, country) in enumerate(get_countryinfo().ISO3)
    #     rv_name1 = Symbol("rateuniforms_$country")
    #     add_RV!(mcs, rv_name1, Uniform(0,1))
    #     add_transform!(mcs, :RCPSSPScenario, :rateuniforms, :(=), rv_name1, [country])
    #     rv_name2 = Symbol("baselineco2_uniforms_$country")
    #     add_RV!(mcs, rv_name2, Uniform(0,1))
    #     add_transform!(mcs, :AbatementCostsCO2, :baselineco2_uniforms, :(=), rv_name2, [country])
    # end

    return mcs
end

# Reformat the RV results into the format used for testing
function reformat_RV_outputs(samplesize::Int; output_path::String=joinpath(@__DIR__, "../output"))

    # create vectors to hold results of Monte Carlo runs
    td = zeros(samplesize);
    tpc = zeros(samplesize);
    tac = zeros(samplesize);
    te = zeros(samplesize);
    ft = zeros(samplesize);
    rt_g = zeros(samplesize);
    s = zeros(samplesize);
    c_co2concentration = zeros(samplesize);
    rgdppercap_slr = zeros(samplesize);
    rgdppercap_market = zeros(samplesize);
    rgdppercap_nonmarket = zeros(samplesize);
    rgdppercap_disc = zeros(samplesize);

    # load raw data
    # no filter
    td      = load_RV("EquityWeighting_td_totaldiscountedimpacts", "td_totaldiscountedimpacts"; output_path=output_path)
    tpc     = load_RV("EquityWeighting_tpc_totalaggregatedcosts", "tpc_totalaggregatedcosts"; output_path=output_path)
    tac     = load_RV("EquityWeighting_tac_totaladaptationcosts", "tac_totaladaptationcosts"; output_path=output_path)
    te      = load_RV("EquityWeighting_te_totaleffect", "te_totaleffect"; output_path=output_path)

    # time index
    c_co2concentration = load_RV("CO2Cycle_c_CO2concentration", "c_CO2concentration"; output_path=output_path)
    ft      = load_RV("TotalForcing_ft_totalforcing", "ft_totalforcing"; output_path=output_path)
    rt_g    = load_RV("GlobalTemperature_rt_g_globaltemperature", "rt_g_globaltemperature"; output_path=output_path)
    s       = load_RV("SeaLevelRise_s_sealevel", "s_sealevel"; output_path=output_path)

    # region index
    rgdppercap_slr          = load_RV("SLRDamages_rgdp_per_cap_SLRRemainGDP", "rgdp_per_cap_SLRRemainGDP"; output_path=output_path)
    rgdppercap_market       = load_RV("MarketDamagesBurke_rgdp_per_cap_MarketRemainGDP", "rgdp_per_cap_MarketRemainGDP"; output_path=output_path)
    rgdppercap_nonmarket    = load_RV("NonMarketDamages_rgdp_per_cap_NonMarketRemainGDP", "rgdp_per_cap_NonMarketRemainGDP"; output_path=output_path)
    rgdppercap_disc         = load_RV("Discontinuity_rgdp_per_cap_NonMarketRemainGDP", "rgdp_per_cap_NonMarketRemainGDP"; output_path=output_path)

    # resave data
    df = DataFrame(td=td, tpc=tpc, tac=tac, te=te, c_co2concentration=c_co2concentration, ft=ft, rt_g=rt_g, sealevel=s, rgdppercap_slr=rgdppercap_slr, rgdppercap_market=rgdppercap_market, rgdppercap_nonmarket=rgdppercap_nonmarket, rgdppercap_di=rgdppercap_disc)
    save(joinpath(output_path, "mimipagemontecarlooutput.csv"), df)

    df
end


function do_monte_carlo_runs(samplesize::Int, scenario::String="RCP4.5 & SSP2", output_path::String=joinpath(@__DIR__, "../output"))
    # get a model
    m = getpage(scenario)
    run(m)

    do_monte_carlo_runs(samplesize, m, output_path)
end

function do_monte_carlo_runs(samplesize::Int, m::Model, output_path::String=joinpath(@__DIR__, "../output"))
    # get simulation
    mcs = getsim()

    # Run
    res = run(mcs, m, samplesize; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)

    # reformat outputs for testing and analysis
    reformat_RV_outputs(samplesize, output_path=output_path)
end
