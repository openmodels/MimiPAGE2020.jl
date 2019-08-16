using Mimi
using Distributions
using CSVFiles
using DataFrames

include("getpagefunction.jl")
include("utils/mctools.jl")

function getsim()
    mcs = @defsim begin

        ############################################################################
        # Define random variables (RVs)
        ############################################################################

        #The folllowing RVs are in more than one component.  For clarity they are
        #set here as opposed to below within the blocks of RVs separated by component
        #so that they are not set more than once.

        save_savingsrate = TriangularDist(10, 20, 15) # components: MarketDamages, MarketDamagesBurke, NonMarketDamages. GDP, SLRDamages

        wincf_weightsfactor_sea["USA"] = TriangularDist(.6, 1, .8) # components: SLRDamages, Discountinuity (weights for market and nonmarket are non-stochastic and uniformly 1)
        wincf_weightsfactor_sea["OECD"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["USSR"] = TriangularDist(.2, .6, .4)
        wincf_weightsfactor_sea["China"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["SEAsia"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["Africa"] = TriangularDist(.4, .8, .6)
        wincf_weightsfactor_sea["LatAmerica"] = TriangularDist(.4, .8, .6)

        automult_autonomouschange = TriangularDist(0.5, 0.8, 0.65)  #components: AdaptationCosts, AbatementCosts

        #The following RVs are divided into blocks by component

        # CO2cycle
        air_CO2fractioninatm = TriangularDist(57, 67, 62)
        res_CO2atmlifetime = TriangularDist(50, 100, 70)
        #ccf_CO2feedback = TriangularDist(0, 0, 0) # only usable if lb <> ub
        ccfmax_maxCO2feedback = TriangularDist(10, 30, 20)
        stay_fractionCO2emissionsinatm = TriangularDist(0.25,0.35,0.3)
        ce_0_basecumCO2emissions=TriangularDist(1830000, 2240000, 2040000)
        a1_percentco2oceanlong=TriangularDist( 4.3,	41.6, 23.0)
        a2_percentco2oceanshort=TriangularDist(23.1, 30.1, 26.6)
        a3_percentco2land=TriangularDist(11.4, 42.5, 27.0)
        t1_timeco2oceanlong=TriangularDist(248.9, 376.2, 312.5)
        t2_timeco2oceanshort=TriangularDist(25.9, 43.9, 34.9)
        t3_timeco2land=TriangularDist(2.8, 5.7, 4.3)
        rt_g0_baseglobaltemp=TriangularDist(0.903, 0.989, 0.946)

        # SiBCASA Permafrost
        PERM_SIB_AF = TriangularDist(1.42609149897258, 2.32504747848815, 1.87556948873036)
        PERM_SIB_SENS_C_CO2 = TriangularDist(28191.1555428869, 35688.3253432574, 31939.7404430722)
        PERM_SIB_LAG_C_CO2 = TriangularDist(35.4926669856915, 87.8949041341782, 61.6937855599349)
        PERM_SIB_POW_C_CO2 = TriangularDist(0.107020247715729, 0.410961185142816, 0.258990716429273)
        PERM_SIB_SENS_C_CH4 = TriangularDist(1240.3553299183, 3348.11995329232, 2294.23764160531)
        PERM_SIB_LAG_C_CH4 = TriangularDist(75.1943160023131, 337.382510123922, 206.288413063117)
        PERM_SIB_POW_C_CH4 = TriangularDist(-0.108779283732708, 0.610889007954489, 0.25105486211089)

        # SulphateForcing
        d_sulphateforcingbase = TriangularDist(-0.8, -0.2, -0.4)
        ind_slopeSEforcing_indirect = TriangularDist(-0.8, 0, -0.4)

        # ClimateTemperature
        frt_warminghalflife = TriangularDist(10, 55, 20)        # from PAGE-ICE v6.2 documentation
        tcr_transientresponse = TriangularDist(0.8, 2.7, 1.8)   # from PAGE-ICE v6.2 documentation
        alb_emulator_rand = TriangularDist(-1., 1., 0.)
        ampf_amplification["EU"] = TriangularDist(1.05, 1.53, 1.23)
        ampf_amplification["USA"] = TriangularDist(1.16, 1.54, 1.32)
        ampf_amplification["OECD"] = TriangularDist(1.14, 1.31, 1.21)
        ampf_amplification["USSR"] = TriangularDist(1.41, 1.9, 1.64)
        ampf_amplification["China"] = TriangularDist(1, 1.3, 1.21)
        ampf_amplification["SEAsia"] = TriangularDist(0.84, 1.15, 1.04)
        ampf_amplification["Africa"] = TriangularDist(0.99, 1.42, 1.22)
        ampf_amplification["LatAmerica"] = TriangularDist(0.9, 1.18, 1.04)

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

        # MarketDamagesRegion and RegionBayes
        impf_coefflinearregion["EU"] = Normal(-7.805769386483104e-5, 6.97374e-5) # linear function does not require multivariate distribution
        impf_coefflinearregion["USA"] = Normal(-0.0030303532741350944, 5.54168e-5)
        impf_coefflinearregion["OECD"] = Normal(-0.0016265205738136398, 7.03004e-5)
        impf_coefflinearregion["USSR"] = Normal(0.003177693763545795, 0.000100497)
        impf_coefflinearregion["China"] = Normal(-0.004360330120678406, 5.58087e-5)
        impf_coefflinearregion["SEAsia"] = Normal(-0.015360663074585796, 0.000144266)
        impf_coefflinearregion["Africa"] = Normal(-0.010746110888392708, 9.44293e-5)
        impf_coefflinearregion["LatAmerica"] = Normal(-0.011690538003738407, 8.5483e-5)


        impfseed_montecarloseedcoeffs = Uniform(0, 10^60)

        impf_coefflinearregion_bayes["EU"] = Normal(0.016778919178202237, 0.000333)
        impf_coefflinearregion_bayes["USA"] = Normal(0.013454251728767158, 0.000264)
        impf_coefflinearregion_bayes["OECD"] = Normal(0.016494824209702184, 0.000354)
        impf_coefflinearregion_bayes["USSR"] = Normal(0.01658623965486268, 0.000483)
        impf_coefflinearregion_bayes["China"] = Normal(0.014147304068527754, 0.000372)
        impf_coefflinearregion_bayes["SEAsia"] = Normal(0.019680709697788883, 0.000553)
        impf_coefflinearregion_bayes["Africa"] = Normal(0.01695479320678946, 0.0001403)
        impf_coefflinearregion_bayes["LatAmerica"] = Normal(0.01743093912793151, 0.0001193)

        impf_coeffquadrregion_bayes["EU"] = Normal(-6.589588822829189e-4, 0.0000130)
        impf_coeffquadrregion_bayes["USA"] = Normal(-4.930689164122343e-4, 0.00000789)
        impf_coeffquadrregion_bayes["OECD"] = Normal(-6.018588172029741e-4, 0.0000117)
        impf_coeffquadrregion_bayes["USSR"] = Normal(-6.503382557688012e-4, 0.0000233)
        impf_coeffquadrregion_bayes["China"] = Normal(-4.8029953805059963e-4, 0.00000965)
        impf_coeffquadrregion_bayes["SEAsia"] = Normal(-6.235809776305397e-4, 0.0000205)
        impf_coeffquadrregion_bayes["Africa"] = Normal(-5.449994771735894e-4, 5.48e-6)
        impf_coeffquadrregion_bayes["LatAmerica"] = Normal(-5.945701704729174e-4, 5.10e-6)

        ### commented out Triangulars following Yumashev et al 2019 (+- 1 standard error)
        #impf_coefflinearregion["EU"] = TriangularDist(-0.000147795139481771, -8.32024824789121e-6, -7.805769386483104e-5)
        #impf_coefflinearregion["USA"] = TriangularDist(-0.00308577012122217, -0.00297493642704801, -0.0030303532741350944)
        #impf_coefflinearregion["OECD"] = TriangularDist(-0.00169682100473875, -0.00155622014288851, -0.0016265205738136398)
        #impf_coefflinearregion["USSR"] = TriangularDist(0.00307719666232785, 0.00327819086476373, 0.003177693763545795)
        #impf_coefflinearregion["China"] = TriangularDist(-0.00441613886251431, -0.00430452137884249, -0.004360330120678406)
        #impf_coefflinearregion["SEAsia"] = TriangularDist(-0.0155049287725219, -0.0152163973766495, -0.015360663074585796)
        #impf_coefflinearregion["Africa"] = TriangularDist(-0.0108405402156084, -0.010651681561177, -0.010746110888392708)
        #impf_coefflinearregion["LatAmerica"] = TriangularDist(-0.0117760209962648, -0.011605055011212, -0.011690538003738407)

        #impf_coefflinearregion_bayes["EU"] = TriangularDist(0.016489555942508, 0.0170682824138964, 0.016778919178202237)
        #impf_coefflinearregion_bayes["USA"] = TriangularDist(0.0130800433972567, 0.0138284600602775, 0.013454251728767158)
        #impf_coefflinearregion_bayes["OECD"] = TriangularDist(0.0159815992534317, 0.0170080491659725, 0.016494824209702184)
        #impf_coefflinearregion_bayes["USSR"] = TriangularDist(0.0161606285309166, 0.0170118507788086, 0.01658623965486268)
        #impf_coefflinearregion_bayes["China"] = TriangularDist(0.0136577868655764, 0.014636821271479, 0.014147304068527754)
        #impf_coefflinearregion_bayes["SEAsia"] = TriangularDist(0.0114260559587677, 0.0279353634368099, 0.019680709697788883)
        #impf_coefflinearregion_bayes["Africa"] = TriangularDist(0.0147353264818791, 0.0191742599316997, 0.01695479320678946)
        #impf_coefflinearregion_bayes["LatAmerica"] = TriangularDist(0.0135798695198007, 0.0212820087360623, 0.01743093912793151)

        #impf_coeffquadrregion_bayes["EU"] = TriangularDist(-0.000670166466563397, -0.000647751298002439, -6.589588822829189e-4)
        #impf_coeffquadrregion_bayes["USA"] = TriangularDist(-0.000504670636236682, -0.000481467196587786, -4.930689164122343e-4)
        #impf_coeffquadrregion_bayes["OECD"] = TriangularDist(-0.000619590167020547, -0.0005841274673854, -6.018588172029741e-4)
        #impf_coeffquadrregion_bayes["USSR"] = TriangularDist(-0.000670961740301304, -0.000629714771236298, -6.503382557688012e-4)
        #impf_coeffquadrregion_bayes["China"] = TriangularDist(-0.00049337406716709, -0.000467225008934108, -4.8029953805059963e-4)
        #impf_coeffquadrregion_bayes["SEAsia"] = TriangularDist(-0.000772519652568207, -0.000474642302692871, -6.235809776305397e-4)
        #impf_coeffquadrregion_bayes["Africa"] = TriangularDist(-0.000588542166552111, -0.000501456787795067, -5.449994771735894e-4)
        #impf_coeffquadrregion_bayes["LatAmerica"] = TriangularDist(-0.000674696054255706, -0.000514444286690128, -5.945701704729174e-4)

        rtl_abs_0_realizedabstemperature["EU"] = TriangularDist(6.76231496767033, 13.482086163781, 10.1222005657257)
        rtl_abs_0_realizedabstemperature["USA"] = TriangularDist(9.54210085883826, 17.3151395362191, 13.4286201975287)
        rtl_abs_0_realizedabstemperature["OECD"] = TriangularDist(9.07596053028087, 15.0507477943984, 12.0633541623396)
        rtl_abs_0_realizedabstemperature["USSR"] = TriangularDist(3.01320548016903, 11.2132204366259, 7.11321295839747)
        rtl_abs_0_realizedabstemperature["China"] = TriangularDist(12.2330402806912, 17.7928749427573, 15.0129576117242)
        rtl_abs_0_realizedabstemperature["SEAsia"] = TriangularDist(23.3863348263352, 26.5136231383473, 24.9499789823412)
        rtl_abs_0_realizedabstemperature["Africa"] = TriangularDist(20.1866940491107, 23.5978086497453, 21.892251349428)
        rtl_abs_0_realizedabstemperature["LatAmerica"] = TriangularDist(19.4846849750102, 22.7561130637973, 21.1203990194037)

        inclerr_includerrorvariance = Normal(1., 0.) # include error variance term in dose-response for Region and RegionBayes

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
        distau_discontinuityexponent = TriangularDist(10, 30, 20)

        # EquityWeighting
        civvalue_civilizationvalue = TriangularDist(1e10, 1e11, 5e10)
        ptp_timepreference = TriangularDist(0.1,2,1)
        emuc_utilityconvexity = TriangularDist(0.5,2,1)

        # AbatementCosts
        AbatementCostParametersCO2_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50,6.0,-22)
        AbatementCostParametersCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-67,6.0,-30)
        AbatementCostParametersN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-20,6.0,-7.0)
        AbatementCostParametersLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50,50,0)

        AbatementCostParametersCO2_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,40,20)
        AbatementCostParametersCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)
        AbatementCostParametersN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)
        AbatementCostParametersLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)

        AbatementCostParametersCO2_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400,-100,-200)
        AbatementCostParametersCH4_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-8000,-1000,-4000)
        AbatementCostParametersN2O_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-15000,0,-7000)
        AbatementCostParametersLin_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400,-100,-200)

        AbatementCostParametersCO2_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60,80,70)
        AbatementCostParametersCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35,70,50)
        AbatementCostParametersN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35,70,50)
        AbatementCostParametersLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60,80,70)

        AbatementCostParametersCO2_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100,700,400)
        AbatementCostParametersCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(3000,10000,6000)
        AbatementCostParametersN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(2000,60000,20000)
        AbatementCostParametersLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100,600,300)

        AbatementCostParametersCO2_ies_InitialExperienceStockofCutbacks = TriangularDist(100000,200000,150000)
        AbatementCostParametersCH4_ies_InitialExperienceStockofCutbacks = TriangularDist(1500,2500,2000)
        AbatementCostParametersN2O_ies_InitialExperienceStockofCutbacks = TriangularDist(30,80,50)
        AbatementCostParametersLin_ies_InitialExperienceStockofCutbacks = TriangularDist(1500,2500,2000)

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
             CO2Cycle.c_CO2concentration,
             TotalForcing.ft_totalforcing,
             ClimateTemperature.rt_g_globaltemperature,
             SeaLevelRise.s_sealevel,
             SLRDamages.rgdp_per_cap_SLRRemainGDP,
             MarketDamagesBurke.rgdp_per_cap_MarketRemainGDP,
             NonMarketDamages.rgdp_per_cap_NonMarketRemainGDP,
             Discontinuity.rgdp_per_cap_NonMarketRemainGDP,
             GDP.ge_growtheffects,
             EquityWeighting.lossinc_includegdplosses,
             EquityWeighting.lgdp_gdploss,
             EquityWeighting.grwnet_realizedgdpgrowth,
             Discontinuity.occurdis_occurrencedummy,
             GDP.cbreg_regionsatbound,
    #         MarketDamagesRegionBayes.impf_coefflinearregion_bayes,
    #         MarketDamagesRegionBayes.impf_coeffquadrregion_bayes,
    #         MarketDamagesRegionBayes.inclerr_includerrorvariance,
    #         MarketDamagesRegionBayes.impfseed_montecarloseedcoeffs
                )

    end #defsim
end

function getsim_ge(ge_minimum::Union{Float64, Nothing} = nothing,
                    ge_maximum::Union{Float64, Nothing} = nothing,
                    ge_mode::Union{Float64, Nothing} = nothing,
                    civvalue_multiplier::Union{Float64, Nothing} = nothing)
    mcs = @defsim begin

        ############################################################################
        # Define random variables (RVs)
        ############################################################################

        #The folllowing RVs are in more than one component.  For clarity they are
        #set here as opposed to below within the blocks of RVs separated by component
        #so that they are not set more than once.

        save_savingsrate = TriangularDist(10, 20, 15) # components: MarketDamages, MarketDamagesBurke, NonMarketDamages. GDP, SLRDamages

        wincf_weightsfactor_sea["USA"] = TriangularDist(.6, 1, .8) # components: SLRDamages, Discountinuity (weights for market and nonmarket are non-stochastic and uniformly 1)
        wincf_weightsfactor_sea["OECD"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["USSR"] = TriangularDist(.2, .6, .4)
        wincf_weightsfactor_sea["China"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["SEAsia"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["Africa"] = TriangularDist(.4, .8, .6)
        wincf_weightsfactor_sea["LatAmerica"] = TriangularDist(.4, .8, .6)

        automult_autonomouschange = TriangularDist(0.5, 0.8, 0.65)  #components: AdaptationCosts, AbatementCosts

        #The following RVs are divided into blocks by component

        # CO2cycle
        air_CO2fractioninatm = TriangularDist(57, 67, 62)
        res_CO2atmlifetime = TriangularDist(50, 100, 70)
        #ccf_CO2feedback = TriangularDist(0, 0, 0) # only usable if lb <> ub
        ccfmax_maxCO2feedback = TriangularDist(10, 30, 20)
        stay_fractionCO2emissionsinatm = TriangularDist(0.25,0.35,0.3)
        ce_0_basecumCO2emissions=TriangularDist(1830000, 2240000, 2040000)
        a1_percentco2oceanlong=TriangularDist( 4.3,	41.6, 23.0)
        a2_percentco2oceanshort=TriangularDist(23.1, 30.1, 26.6)
        a3_percentco2land=TriangularDist(11.4, 42.5, 27.0)
        t1_timeco2oceanlong=TriangularDist(248.9, 376.2, 312.5)
        t2_timeco2oceanshort=TriangularDist(25.9, 43.9, 34.9)
        t3_timeco2land=TriangularDist(2.8, 5.7, 4.3)
        rt_g0_baseglobaltemp=TriangularDist(0.903, 0.989, 0.946)

        # SulphateForcing
        d_sulphateforcingbase = TriangularDist(-0.8, -0.2, -0.4)
        ind_slopeSEforcing_indirect = TriangularDist(-0.8, 0, -0.4)

        # ClimateTemperature
        frt_warminghalflife = TriangularDist(10, 55, 20)        # from PAGE-ICE v6.2 documentation
        tcr_transientresponse = TriangularDist(0.8, 2.7, 1.8)   # from PAGE-ICE v6.2 documentation
        ampf_amplification["EU"] = TriangularDist(1.05, 1.53, 1.23)
        ampf_amplification["USA"] = TriangularDist(1.16, 1.54, 1.32)
        ampf_amplification["OECD"] = TriangularDist(1.14, 1.31, 1.21)
        ampf_amplification["USSR"] = TriangularDist(1.41, 1.9, 1.64)
        ampf_amplification["China"] = TriangularDist(1, 1.3, 1.21)
        ampf_amplification["SEAsia"] = TriangularDist(0.84, 1.15, 1.04)
        ampf_amplification["Africa"] = TriangularDist(0.99, 1.42, 1.22)
        ampf_amplification["LatAmerica"] = TriangularDist(0.9, 1.18, 1.04)

        # SeaLevelRise
        s0_initialSL = TriangularDist(0.17, 0.21, 0.19)                             # taken from PAGE-ICE v6.20 default
        sltemp_SLtemprise = TriangularDist(0.7, 3., 1.5)                            # median sensitivity to GMST changes
        sla_SLbaselinerise = TriangularDist(0.5, 1.5, 1.)                           # asymptote for pre-industrial
        sltau_SLresponsetime = Gamma(16.0833333333333333, 24.)                      # fat-tailed distribution of time constant T_sl, sea level response time, from mode=362, mean = 386

        # GDP
        isat0_initialimpactfxnsaturation = TriangularDist(15, 25, 20)
        ge_growtheffects = TriangularDist(ge_minimum, ge_maximum, ge_mode)

        # MarketDamages
        tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.)
        iben_MarketInitialBenefit = TriangularDist(0, .3, .1)
        W_MarketImpactsatCalibrationTemp = TriangularDist(.2, .8, .5)
        pow_MarketImpactExponent = TriangularDist(1.5, 3, 2)
        ipow_MarketIncomeFxnExponent = TriangularDist(-.3, 0, -.1)

        # MarketDamagesBurke
        impf_coeff_lin = TriangularDist(-0.0139791885347898, -0.0026206307945989, -0.00829990966469437)
        impf_coeff_quadr = TriangularDist(-0.000599999506482576, -0.000400007300924579, -0.000500003403703578)

        # MarketDamagesRegion and RegionBayes
        impf_coefflinearregion["EU"] = Normal(-7.805769386483104e-5, 6.97374e-5) # linear function does not require multivariate distribution
        impf_coefflinearregion["USA"] = Normal(-0.0030303532741350944, 5.54168e-5)
        impf_coefflinearregion["OECD"] = Normal(-0.0016265205738136398, 7.03004e-5)
        impf_coefflinearregion["USSR"] = Normal(0.003177693763545795, 0.000100497)
        impf_coefflinearregion["China"] = Normal(-0.004360330120678406, 5.58087e-5)
        impf_coefflinearregion["SEAsia"] = Normal(-0.015360663074585796, 0.000144266)
        impf_coefflinearregion["Africa"] = Normal(-0.010746110888392708, 9.44293e-5)
        impf_coefflinearregion["LatAmerica"] = Normal(-0.011690538003738407, 8.5483e-5)


        impfseed_montecarloseedcoeffs = Uniform(0, 10^60)

        impf_coefflinearregion_bayes["EU"] = Normal(0.016778919178202237, 0.000333)
        impf_coefflinearregion_bayes["USA"] = Normal(0.013454251728767158, 0.000264)
        impf_coefflinearregion_bayes["OECD"] = Normal(0.016494824209702184, 0.000354)
        impf_coefflinearregion_bayes["USSR"] = Normal(0.01658623965486268, 0.000483)
        impf_coefflinearregion_bayes["China"] = Normal(0.014147304068527754, 0.000372)
        impf_coefflinearregion_bayes["SEAsia"] = Normal(0.019680709697788883, 0.000553)
        impf_coefflinearregion_bayes["Africa"] = Normal(0.01695479320678946, 0.0001403)
        impf_coefflinearregion_bayes["LatAmerica"] = Normal(0.01743093912793151, 0.0001193)

        impf_coeffquadrregion_bayes["EU"] = Normal(-6.589588822829189e-4, 0.0000130)
        impf_coeffquadrregion_bayes["USA"] = Normal(-4.930689164122343e-4, 0.00000789)
        impf_coeffquadrregion_bayes["OECD"] = Normal(-6.018588172029741e-4, 0.0000117)
        impf_coeffquadrregion_bayes["USSR"] = Normal(-6.503382557688012e-4, 0.0000233)
        impf_coeffquadrregion_bayes["China"] = Normal(-4.8029953805059963e-4, 0.00000965)
        impf_coeffquadrregion_bayes["SEAsia"] = Normal(-6.235809776305397e-4, 0.0000205)
        impf_coeffquadrregion_bayes["Africa"] = Normal(-5.449994771735894e-4, 5.48e-6)
        impf_coeffquadrregion_bayes["LatAmerica"] = Normal(-5.945701704729174e-4, 5.10e-6)

        ### commented out Triangulars following Yumashev et al 2019 (+- 1 standard error)
        #impf_coefflinearregion["EU"] = TriangularDist(-0.000147795139481771, -8.32024824789121e-6, -7.805769386483104e-5)
        #impf_coefflinearregion["USA"] = TriangularDist(-0.00308577012122217, -0.00297493642704801, -0.0030303532741350944)
        #impf_coefflinearregion["OECD"] = TriangularDist(-0.00169682100473875, -0.00155622014288851, -0.0016265205738136398)
        #impf_coefflinearregion["USSR"] = TriangularDist(0.00307719666232785, 0.00327819086476373, 0.003177693763545795)
        #impf_coefflinearregion["China"] = TriangularDist(-0.00441613886251431, -0.00430452137884249, -0.004360330120678406)
        #impf_coefflinearregion["SEAsia"] = TriangularDist(-0.0155049287725219, -0.0152163973766495, -0.015360663074585796)
        #impf_coefflinearregion["Africa"] = TriangularDist(-0.0108405402156084, -0.010651681561177, -0.010746110888392708)
        #impf_coefflinearregion["LatAmerica"] = TriangularDist(-0.0117760209962648, -0.011605055011212, -0.011690538003738407)

        #impf_coefflinearregion_bayes["EU"] = TriangularDist(0.016489555942508, 0.0170682824138964, 0.016778919178202237)
        #impf_coefflinearregion_bayes["USA"] = TriangularDist(0.0130800433972567, 0.0138284600602775, 0.013454251728767158)
        #impf_coefflinearregion_bayes["OECD"] = TriangularDist(0.0159815992534317, 0.0170080491659725, 0.016494824209702184)
        #impf_coefflinearregion_bayes["USSR"] = TriangularDist(0.0161606285309166, 0.0170118507788086, 0.01658623965486268)
        #impf_coefflinearregion_bayes["China"] = TriangularDist(0.0136577868655764, 0.014636821271479, 0.014147304068527754)
        #impf_coefflinearregion_bayes["SEAsia"] = TriangularDist(0.0114260559587677, 0.0279353634368099, 0.019680709697788883)
        #impf_coefflinearregion_bayes["Africa"] = TriangularDist(0.0147353264818791, 0.0191742599316997, 0.01695479320678946)
        #impf_coefflinearregion_bayes["LatAmerica"] = TriangularDist(0.0135798695198007, 0.0212820087360623, 0.01743093912793151)

        #impf_coeffquadrregion_bayes["EU"] = TriangularDist(-0.000670166466563397, -0.000647751298002439, -6.589588822829189e-4)
        #impf_coeffquadrregion_bayes["USA"] = TriangularDist(-0.000504670636236682, -0.000481467196587786, -4.930689164122343e-4)
        #impf_coeffquadrregion_bayes["OECD"] = TriangularDist(-0.000619590167020547, -0.0005841274673854, -6.018588172029741e-4)
        #impf_coeffquadrregion_bayes["USSR"] = TriangularDist(-0.000670961740301304, -0.000629714771236298, -6.503382557688012e-4)
        #impf_coeffquadrregion_bayes["China"] = TriangularDist(-0.00049337406716709, -0.000467225008934108, -4.8029953805059963e-4)
        #impf_coeffquadrregion_bayes["SEAsia"] = TriangularDist(-0.000772519652568207, -0.000474642302692871, -6.235809776305397e-4)
        #impf_coeffquadrregion_bayes["Africa"] = TriangularDist(-0.000588542166552111, -0.000501456787795067, -5.449994771735894e-4)
        #impf_coeffquadrregion_bayes["LatAmerica"] = TriangularDist(-0.000674696054255706, -0.000514444286690128, -5.945701704729174e-4)

        rtl_abs_0_realizedabstemperature["EU"] = TriangularDist(6.76231496767033, 13.482086163781, 10.1222005657257)
        rtl_abs_0_realizedabstemperature["USA"] = TriangularDist(9.54210085883826, 17.3151395362191, 13.4286201975287)
        rtl_abs_0_realizedabstemperature["OECD"] = TriangularDist(9.07596053028087, 15.0507477943984, 12.0633541623396)
        rtl_abs_0_realizedabstemperature["USSR"] = TriangularDist(3.01320548016903, 11.2132204366259, 7.11321295839747)
        rtl_abs_0_realizedabstemperature["China"] = TriangularDist(12.2330402806912, 17.7928749427573, 15.0129576117242)
        rtl_abs_0_realizedabstemperature["SEAsia"] = TriangularDist(23.3863348263352, 26.5136231383473, 24.9499789823412)
        rtl_abs_0_realizedabstemperature["Africa"] = TriangularDist(20.1866940491107, 23.5978086497453, 21.892251349428)
        rtl_abs_0_realizedabstemperature["LatAmerica"] = TriangularDist(19.4846849750102, 22.7561130637973, 21.1203990194037)

        inclerr_includerrorvariance = Normal(1., 0.) # include error variance term in dose-response for Region and RegionBayes

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
        distau_discontinuityexponent = TriangularDist(10, 30, 20)

        # EquityWeighting
        civvalue_civilizationvalue = TriangularDist(1e10 * civvalue_multiplier,
                                                    1e11 * civvalue_multiplier,
                                                    5e10 * civvalue_multiplier)
        ptp_timepreference = TriangularDist(0.1,2,1)
        emuc_utilityconvexity = TriangularDist(0.5,2,1)

        # AbatementCosts
        AbatementCostParametersCO2_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50,6.0,-22)
        AbatementCostParametersCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-67,6.0,-30)
        AbatementCostParametersN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-20,6.0,-7.0)
        AbatementCostParametersLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50,50,0)

        AbatementCostParametersCO2_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,40,20)
        AbatementCostParametersCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)
        AbatementCostParametersN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)
        AbatementCostParametersLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0,20,10)

        AbatementCostParametersCO2_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400,-100,-200)
        AbatementCostParametersCH4_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-8000,-1000,-4000)
        AbatementCostParametersN2O_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-15000,0,-7000)
        AbatementCostParametersLin_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400,-100,-200)

        AbatementCostParametersCO2_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60,80,70)
        AbatementCostParametersCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35,70,50)
        AbatementCostParametersN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35,70,50)
        AbatementCostParametersLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60,80,70)

        AbatementCostParametersCO2_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100,700,400)
        AbatementCostParametersCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(3000,10000,6000)
        AbatementCostParametersN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(2000,60000,20000)
        AbatementCostParametersLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100,600,300)

        AbatementCostParametersCO2_ies_InitialExperienceStockofCutbacks = TriangularDist(100000,200000,150000)
        AbatementCostParametersCH4_ies_InitialExperienceStockofCutbacks = TriangularDist(1500,2500,2000)
        AbatementCostParametersN2O_ies_InitialExperienceStockofCutbacks = TriangularDist(30,80,50)
        AbatementCostParametersLin_ies_InitialExperienceStockofCutbacks = TriangularDist(1500,2500,2000)

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
             CO2Cycle.c_CO2concentration,
             TotalForcing.ft_totalforcing,
             ClimateTemperature.rt_g_globaltemperature,
             SeaLevelRise.s_sealevel,
             SLRDamages.rgdp_per_cap_SLRRemainGDP,
             MarketDamagesBurke.rgdp_per_cap_MarketRemainGDP,
             NonMarketDamages.rgdp_per_cap_NonMarketRemainGDP,
             Discontinuity.rgdp_per_cap_NonMarketRemainGDP,
             GDP.ge_growtheffects,
             EquityWeighting.lossinc_includegdplosses,
             EquityWeighting.lgdp_gdploss,
             EquityWeighting.grwnet_realizedgdpgrowth,
             Discontinuity.occurdis_occurrencedummy,
             GDP.cbreg_regionsatbound)

    end #defsim
end

#Reformat the RV results into the format used for testing
function reformat_RV_outputs(samplesize::Int; output_path::String = joinpath(@__DIR__, "../output/"))

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
    td      = load_RV("td_totaldiscountedimpacts"; output_path = output_path)
    tpc     = load_RV("tpc_totalaggregatedcosts"; output_path = output_path)
    tac     = load_RV("tac_totaladaptationcosts"; output_path = output_path)
    te      = load_RV("te_totaleffect"; output_path = output_path)

    #time index
    c_co2concentration = load_RV("c_CO2concentration"; output_path = output_path)
    ft      = load_RV("ft_totalforcing"; output_path = output_path)
    rt_g    = load_RV("rt_g_globaltemperature"; output_path = output_path)
    s       = load_RV("s_sealevel"; output_path = output_path)

    #region index
    rgdppercap_slr          = load_RV("rgdp_per_cap_SLRRemainGDP"; output_path = output_path)
    rgdppercap_slr          = load_RV("rgdp_per_cap_SLRRemainGDP"; output_path = output_path)
    rgdppercap_market       = load_RV("rgdp_per_cap_MarketRemainGDP"; output_path = output_path)
    rgdppercap_nonmarket    =load_RV("rgdp_per_cap_NonMarketRemainGDP"; output_path = output_path)
    rgdppercap_disc         = load_RV("rgdp_per_cap_NonMarketRemainGDP"; output_path = output_path)

    #resave data
    df=DataFrame(td=td,tpc=tpc,tac=tac,te=te,c_co2concentration=c_co2concentration,ft=ft,rt_g=rt_g,sealevel=s,rgdppercap_slr=rgdppercap_slr,rgdppercap_market=rgdppercap_market,rgdppercap_nonmarket=rgdppercap_nonmarket,rgdppercap_di=rgdppercap_disc)
    save(joinpath(output_path, "mimipagemontecarlooutput.csv"),df)
end

function do_monte_carlo_runs(samplesize::Int, output_path::String = joinpath(@__DIR__, "../output"))
    # get simulation
    mcs = getsim()

    # get a model
    m = getpage()
    run(m)

    # Generate trial data for all RVs and save to a file
    generate_trials!(mcs, samplesize, filename = joinpath(output_path, "trialdata.csv"))

    # set model
    set_models!(mcs, m)

    # Run trials 1:samplesize, and save results to the indicated directory, one CSV file per RV
    run_sim(mcs, output_dir = output_path)

    # reformat outputs for testing and analysis
    reformat_RV_outputs(samplesize, output_path=output_path)
end

function get_scc_mcs(samplesize::Int, year::Int, output_path::String = joinpath(@__DIR__, "../output");
                     eta::Union{Float64, Nothing} = nothing, prtp::Union{Float64, Nothing} = nothing,
                     pulse_size::Union{Float64, Nothing} = 100000.,
                     switch_off::String = "none",
                     scenario::String = "NDCs")
    # Setup the marginal model
    m = getpage(scenario)

    # optionally switch off a component
    if switch_off == "market"
        update_param!(m, :switchoff_marketdamages, 1.)
    elseif switch_off == "nonmarket"
        update_param!(m, :switchoff_nonmarketdamages, 1.)
    elseif switch_off == "slr"
        update_param!(m, :switchoff_SLRdamages, 1.)
    elseif switch_off == "disc"
        update_param!(m, :switchoff_discontinuity, 1.)
    end
    mm = compute_scc_mm(m, year=year, eta=eta, prtp=prtp, pulse_size=pulse_size)[:mm]

    # Setup SCC calculation and place for results
    scc_results = zeros(Float64, samplesize, 19)

    function my_scc_calculation(mcs::Simulation, trialnum::Int, ntimesteps::Int, tup::Union{Tuple, Nothing})
        base, marginal = mcs.models
        scc_results[trialnum, 1] = (marginal[:EquityWeighting, :td_totaldiscountedimpacts] - base[:EquityWeighting, :td_totaldiscountedimpacts]) / pulse_size

        for jj_region in [1,2,3,4,5,6,7,8]
            scc_results[trialnum, 1 + jj_region] = (sum(marginal[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:,jj_region]) - sum(base[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, jj_region])) / pulse_size
        end

        for jj_timestep in [1,2,3,4,5,6,7,8,9,10]
            scc_results[trialnum, 9 + jj_timestep] = (sum(marginal[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][jj_timestep, :]) - sum(base[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][jj_timestep, :])) / pulse_size
        end
    end

    # Setup MC simulation
    mcs = getsim()
    set_models!(mcs, [mm.base, mm.marginal])
    generate_trials!(mcs, samplesize, filename = joinpath(output_path, "scc_trials.csv"))

    # Run it!
    run_sim(mcs, output_dir=output_path, post_trial_func=my_scc_calculation)

    scc_results
end

## add another MCS function that allows to change certain model parameters
function get_scc_mcs_ge(samplesize::Int, year::Int, output_path::String = joinpath(@__DIR__, "../output");
                     eta::Union{Float64, Nothing} = nothing, prtp::Union{Float64, Nothing} = nothing,
                     pulse_size::Union{Float64, Nothing} = 100000.,
                     gdpincl::Union{Float64, Nothing} = 0.,
                     ge_minimum::Union{Float64, Nothing} = 0.,
                     ge_mode::Union{Float64, Nothing} = nothing, # Mode must be set manually
                     ge_maximum::Union{Float64, Nothing} = 1.,
                     cbshare::Union{Float64, Nothing} = 5.,
                     eqwshare::Union{Float64, Nothing} = 0.99,
                     scenario::String = "NDCs",
                     civvalue_multiplier::Float64 = 10000.)

    # require parameter setting for the ge distribution
    if ge_minimum === nothing || ge_mode === nothing || ge_maximum === nothing
        error("The minimum, mode and maximum of ge_growtheffects must be set manually. Please set ge_minimum, ge_maximum and ge_mode in get_scc_mcs_ge().")
    end

    # Setup the marginal model
    m = getpage()

    # update the parameters using function inputs
    update_param!(m, :lossinc_includegdplosses, gdpincl)
    update_param!(m, :cbshare_pcconsumptionboundshare, cbshare)
    update_param!(m, :eqwshare_shareofweighteddamages, eqwshare)

    mm = compute_scc_mm(m, year=year, eta=eta, prtp=prtp, pulse_size=pulse_size)[:mm]

    # Setup SCC calculation and place for results
    scc_results = zeros(Float64, samplesize, 19)

    function my_scc_calculation(mcs::Simulation, trialnum::Int, ntimesteps::Int, tup::Union{Tuple, Nothing})
        base, marginal = mcs.models
        scc_results[trialnum, 1] = (marginal[:EquityWeighting, :td_totaldiscountedimpacts] - base[:EquityWeighting, :td_totaldiscountedimpacts]) / pulse_size

        for jj_region in [1,2,3,4,5,6,7,8]
            scc_results[trialnum, 1 + jj_region] = (sum(marginal[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:,jj_region]) - sum(base[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, jj_region])) / pulse_size
        end

        for jj_timestep in [1,2,3,4,5,6,7,8,9,10]
            scc_results[trialnum, 9 + jj_timestep] = (sum(marginal[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][jj_timestep, :]) - sum(base[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][jj_timestep, :])) / pulse_size
        end
    end

    # Setup MC simulation
    mcs = getsim_ge(ge_minimum, ge_maximum, ge_mode,
                    civvalue_multiplier)
    set_models!(mcs, [mm.base, mm.marginal])
    generate_trials!(mcs, samplesize, filename = joinpath(output_path, "scc_trials.csv"))

    # Run it!
    run_sim(mcs, output_dir=output_path, post_trial_func=my_scc_calculation)

    scc_results
end
# do_monte_carlo_runs(100)

# include("mcs.jl")
# include("compute_scc.jl")
# get_scc_mcs(100, 2020)
