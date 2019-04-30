using Mimi
using Distributions
using CSVFiles
using DataFrames

include("getpagefunction.jl")
include("utils/mctools.jl")

m = getpage()
run(m)

mcs = @defmcs begin

    ############################################################################
    # Define random variables (RVs)
    ############################################################################

    #The folllowing RVs are in more than one component.  For clarity they are
    #set here as opposed to below within the blocks of RVs separated by component
    #so that they are not set more than once.

    save_savingsrate = TriangularDist(10, 20, 15) # components: MarketDamages, NonMarketDamages. GDP, SLRDamages

    wincf_weightsfactor["USA"] = TriangularDist(.6, 1, .8) # components: MarketDamages, NonMarketDamages, , SLRDamages, Discountinuity
    wincf_weightsfactor["OECD"] = TriangularDist(.4, 1.2, .8)
    wincf_weightsfactor["USSR"] = TriangularDist(.2, .6, .4)
    wincf_weightsfactor["China"] = TriangularDist(.4, 1.2, .8)
    wincf_weightsfactor["SEAsia"] = TriangularDist(.4, 1.2, .8)
    wincf_weightsfactor["Africa"] = TriangularDist(.4, .8, .6)
    wincf_weightsfactor["LatAmerica"] = TriangularDist(.4, .8, .6)

    automult_autonomouschange = TriangularDist(0.5, 0.8, 0.65)  #components: AdaptationCosts, AbatementCosts

    #The following RVs are divided into blocks by component

    # CO2cycle
    air_CO2fractioninatm = TriangularDist(57, 67, 62)
    res_CO2atmlifetime = TriangularDist(50, 100, 70)
    ccf_CO2feedback = TriangularDist(0, 0, 0)
    ccfmax_maxCO2feedback = TriangularDist(10, 20, 30)
    stay_fractionCO2emissionsinatm = TriangularDist(0.25,0.35,0.3)
    ce_0_basecumCO2emissions=TriangularDist(1830000,2040000,2240000)
    a1_percentco2oceanlong=TriangularDist( 4.3,	23.0, 41.6)
    a2_percentco2oceanshort=TriangularDist(23.1, 26.6, 30.1)
    a3_percentco2land=TriangularDist(11.4, 27.0,	42.5)
    t1_timeco2oceanlong=TriangularDist(248.9, 312.5, 376.2)
    t2_timeco2oceanshort=TriangularDist(25.9, 34.9,	43.9)
    t3_timeco2land=TriangularDist(2.8, 4.3, 5.7)
    rt_g0_baseglobaltemp=TriangularDist(0.903,0.946,0.989)

    # SulphateForcing
    d_sulphateforcingbase = TriangularDist(-0.8, -0.2, -0.4)
    ind_slopeSEforcing_indirect = TriangularDist(-0.8, 0, -0.4)

    # ClimateTemperature
    rlo_ratiolandocean = TriangularDist(1.2, 1.6, 1.4)
    pole_polardifference = TriangularDist(1, 2, 1.5)
    frt_warminghalflife = TriangularDist(10, 55, 20)        # from PAGE-ICE v6.2 documentation
    tcr_transientresponse = TriangularDist(0.8, 2.7, 1.8)   # from PAGE-ICE v6.2 documentation

    # SeaLevelRise
    s0_initialSL = TriangularDist(0.17, 0.21, 0.19)                             # taken from PAGE-ICE v6.20 default
    sltemp_SLtemprise = TriangularDist(0.7, 3., 1.5)                            # median sensitivity to GMST changes
    sla_SLbaselinerise = TriangularDist(0.5, 1.5, 1.)                           # asymptote for pre-industrial
    sltau_SLresponsetime = Gamma(16.0833333333333333, 24.)                      # fat-tailed distribution of time constant T_sl, sea level response time, from mode=362, mean = 386

    # GDP
    isat0_initialimpactfxnsaturation = TriangularDist(15, 25, 20)

    # MarketDamages
    tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.)
    iben_MarketInitialBenefit = TriangularDist(0, .3, .1)
    W_MarketImpactsatCalibrationTemp = TriangularDist(.2, .8, .5)
    pow_MarketImpactExponent = TriangularDist(1.5, 3, 2)
    ipow_MarketIncomeFxnExponent = TriangularDist(-.3, 0, -.1)

    # MarketDamagesBurke
    impf_coeff_lin = TriangularDist(-0.0139791885347898, -0.0026206307945989, -0.00829990966469437)
    impf_coeff_quadr = TriangularDist(-0.000599999506482576, -0.000400007300924579, -0.000500003403703578)

    # NonMarketDamages
    tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.)
    iben_NonMarketInitialBenefit = TriangularDist(0, .2, .05)
    w_NonImpactsatCalibrationTemp = TriangularDist(.1, 1, .5)
    pow_NonMarketExponent = TriangularDist(1.5, 3, 2)
    ipow_NonMarketIncomeFxnExponent = TriangularDist(-.2, .2, 0)

    # SLRDamages
    scal_calibrationSLR = TriangularDist(0.45, 0.55, .5)
    #iben_SLRInitialBenefit = TriangularDist(0, 0, 0) # only usable if lb <> ub
    W_SatCalibrationSLR = TriangularDist(.5, 1.5, 1)
    pow_SLRImpactFxnExponent = TriangularDist(.5, 1, .7)
    ipow_SLRIncomeFxnExponent = TriangularDist(-.4, -.2, -.3)

    # Discountinuity
    rand_discontinuity = Uniform(0, 1)
    tdis_tolerabilitydisc = TriangularDist(1, 2, 1.5)
    pdis_probability = TriangularDist(10, 30, 20)
    wdis_gdplostdisc = TriangularDist(1, 5, 3)
    ipow_incomeexponent = TriangularDist(-.3, 0, -.1)
    distau_discontinuityexponent = TriangularDist(20, 200, 50)

    # EquityWeighting
    civvalue_civilizationvalue = TriangularDist(1e10, 1e11, 5e10)
    ptp_timepreference = TriangularDist(0.1,2,1)
    emuc_utilityconvexity = TriangularDist(0.5,2,1)

    # AbatementCosts
    AbatementCostsCO2_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50,6.0,-22)
    AbatementCostsCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-67,6.0,-30)
    AbatementCostsN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-20,6.0,-7.0)
    AbatementCostsLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50,50,0)

    AbatementCostsCO2_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,40,20)
    AbatementCostsCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)
    AbatementCostsN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)
    AbatementCostsLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)

    AbatementCostsCO2_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400,-100,-200)
    AbatementCostsCH4_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-8000,-1000,-4000)
    AbatementCostsN2O_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-15000,0,-7000)
    AbatementCostsLin_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400,-100,-200)

    AbatementCostsCO2_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60,80,70)
    AbatementCostsCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35,70,50)
    AbatementCostsN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35,70,50)
    AbatementCostsLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60,80,70)

    AbatementCostsCO2_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100,700,400)
    AbatementCostsCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(3000,10000,6000)
    AbatementCostsN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(2000,60000,20000)
    AbatementCostsLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100,600,300)

    AbatementCostsCO2_ies_InitialExperienceStockofCutbacks = TriangularDist(100000,200000,150000)
    AbatementCostsCH4_ies_InitialExperienceStockofCutbacks = TriangularDist(1500,2500,2000)
    AbatementCostsN2O_ies_InitialExperienceStockofCutbacks = TriangularDist(30,80,50)
    AbatementCostsLin_ies_InitialExperienceStockofCutbacks = TriangularDist(1500,2500,2000)

    #the following variables need to be set, but set the same in all 4 abatement cost components
    #note that for these regional variables, the first region is the focus region (EU), which is set in the preceding code, and so is always one for these variables

    emitf_uncertaintyinBAUemissfactor["USA"] = TriangularDist(0.8,1.2,1.0)
    emitf_uncertaintyinBAUemissfactor["OECD"] = TriangularDist(0.8,1.2,1.0)
    emitf_uncertaintyinBAUemissfactor["USSR"] = TriangularDist(0.65,1.35,1.0)
    emitf_uncertaintyinBAUemissfactor["China"] = TriangularDist(0.5,1.5,1.0)
    emitf_uncertaintyinBAUemissfactor["SEAsia"] = TriangularDist(0.5,1.5,1.0)
    emitf_uncertaintyinBAUemissfactor["Africa"] = TriangularDist(0.5,1.5,1.0)
    emitf_uncertaintyinBAUemissfactor["LatAmerica"] = TriangularDist(0.5,1.5,1.0)

    q0f_negativecostpercentagefactor["USA"] = TriangularDist(0.75,1.5,1.0)
    q0f_negativecostpercentagefactor["OECD"] = TriangularDist(0.75,1.25,1.0)
    q0f_negativecostpercentagefactor["USSR"] = TriangularDist(0.4,1.0,0.7)
    q0f_negativecostpercentagefactor["China"] = TriangularDist(0.4,1.0,0.7)
    q0f_negativecostpercentagefactor["SEAsia"] = TriangularDist(0.4,1.0,0.7)
    q0f_negativecostpercentagefactor["Africa"] = TriangularDist(0.4,1.0,0.7)
    q0f_negativecostpercentagefactor["LatAmerica"] = TriangularDist(0.4,1.0,0.7)

    cmaxf_maxcostfactor["USA"] = TriangularDist(0.8,1.2,1.0)
    cmaxf_maxcostfactor["OECD"] = TriangularDist(1.0,1.5,1.2)
    cmaxf_maxcostfactor["USSR"] = TriangularDist(0.4,1.0,0.7)
    cmaxf_maxcostfactor["China"] = TriangularDist(0.8,1.2,1.0)
    cmaxf_maxcostfactor["SEAsia"] = TriangularDist(1,1.5,1.2)
    cmaxf_maxcostfactor["Africa"] = TriangularDist(1,1.5,1.2)
    cmaxf_maxcostfactor["LatAmerica"] = TriangularDist(0.4,1.0,0.7)

    q0propmult_cutbacksatnegativecostinfinalyear = TriangularDist(0.3,1.2,0.7)
    qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear = TriangularDist(1,1.5,1.3)
    c0mult_mostnegativecostinfinalyear = TriangularDist(0.5,1.2,0.8)
    curve_below_curvatureofMACcurvebelowzerocost = TriangularDist(0.25,0.8,0.45)
    curve_above_curvatureofMACcurveabovezerocost = TriangularDist(0.1,0.7,0.4)
    cross_experiencecrossoverratio = TriangularDist(0.1,0.3,0.2)
    learn_learningrate = TriangularDist(0.05,0.35,0.2)

    # AdaptationCosts
    AdaptiveCostsSeaLevel_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
    AdaptiveCostsSeaLevel_ci_costimpact_eu = TriangularDist(0.0005, 0.002, 0.001)
    AdaptiveCostsEconomic_cp_costplateau_eu = TriangularDist(0.005, 0.02, 0.01)
    AdaptiveCostsEconomic_ci_costimpact_eu = TriangularDist(0.001, 0.008, 0.003)
    AdaptiveCostsNonEconomic_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
    AdaptiveCostsNonEconomic_ci_costimpact_eu = TriangularDist(0.002, 0.01, 0.005)

    cf_costregional["USA"] = TriangularDist(0.6, 1, 0.8)
    cf_costregional["OECD"] = TriangularDist(0.4, 1.2, 0.8)
    cf_costregional["USSR"] = TriangularDist(0.2, 0.6, 0.4)
    cf_costregional["China"] = TriangularDist(0.4, 1.2, 0.8)
    cf_costregional["SEAsia"] = TriangularDist(0.4, 1.2, 0.8)
    cf_costregional["Africa"] = TriangularDist(0.4, 0.8, 0.6)
    cf_costregional["LatAmerica"] = TriangularDist(0.4, 0.8, 0.6)

    ############################################################################
    # Indicate which parameters to save for each model run
    ############################################################################

    save(EquityWeighting.td_totaldiscountedimpacts,
        EquityWeighting.tpc_totalaggregatedcosts,
        EquityWeighting.tac_totaladaptationcosts,
        EquityWeighting.te_totaleffect,
        co2cycle.c_CO2concentration,
        TotalForcing.ft_totalforcing,
        ClimateTemperature.rt_g_globaltemperature,
        SeaLevelRise.s_sealevel,
        SLRDamages.rgdp_per_cap_SLRRemainGDP,
        MarketDamages.rgdp_per_cap_MarketRemainGDP,
        NonMarketDamages.rgdp_per_cap_NonMarketRemainGDP,
        Discontinuity.rgdp_per_cap_NonMarketRemainGDP)

end #defmcs

#Reformat the RV results into the format used for testing
function reformat_RV_outputs(samplesize::Int; outputpath::String = joinpath(@__DIR__, "../../output/"))

    #create vectors to hold results of Monte Carlo runs
    td=zeros(samplesize);
    tpc=zeros(samplesize);
    tac=zeros(samplesize);
    te=zeros(samplesize);
    ft=zeros(samplesize);
    rt_g=zeros(samplesize);
    s=zeros(samplesize);
    c_co2concentration=zeros(samplesize);
    rgdppercap_slr=zeros(samplesize);
    rgdppercap_market=zeros(samplesize);
    rgdppercap_nonmarket=zeros(samplesize);
    rgdppercap_disc=zeros(samplesize);

    #load raw data
    #no filter
    td      = load_RV("td_totaldiscountedimpacts")
    tpc     = load_RV("tpc_totalaggregatedcosts")
    tac     = load_RV("tac_totaladaptationcosts")
    te      = load_RV("te_totaleffect")

    #time index
    c_co2concentration = load_RV("c_CO2concentration")
    ft      = load_RV("ft_totalforcing")
    rt_g    = load_RV("rt_g_globaltemperature")
    s       = load_RV("s_sealevel")

    #region index
    rgdppercap_slr          = load_RV("rgdp_per_cap_SLRRemainGDP")
    rgdppercap_slr          = load_RV("rgdp_per_cap_SLRRemainGDP")
    rgdppercap_market       = load_RV("rgdp_per_cap_MarketRemainGDP")
    rgdppercap_nonmarket    =load_RV("rgdp_per_cap_NonMarketRemainGDP")
    rgdppercap_disc         = load_RV("rgdp_per_cap_NonMarketRemainGDP")

    #resave data
    df=DataFrame(td=td,tpc=tpc,tac=tac,te=te,c_co2concentration=c_co2concentration,ft=ft,rt_g=rt_g,sealevel=s,rgdppercap_slr=rgdppercap_slr,rgdppercap_market=rgdppercap_market,rgdppercap_nonmarket=rgdppercap_nonmarket,rgdppercap_di=rgdppercap_disc)
    save(joinpath(@__DIR__, "../output/mimipagemontecarlooutput.csv"),df)
end

function do_monte_carlo_runs(samplesize::Int)

        # Generate trial data for all RVs and save to a file
        generate_trials!(mcs, samplesize, filename = joinpath(@__DIR__, "../output/trialdata.csv"))

        # set model
        Mimi.set_model!(mcs, m)

        # Run trials 1:samplesize, and save results to the indicated directory, one CSV file per RV
        run_mcs(mcs, samplesize, output_dir = joinpath(@__DIR__, "../output/"))

        # reformat outputs for testing and analysis
        reformat_RV_outputs(samplesize)
end
