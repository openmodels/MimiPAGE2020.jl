
# create the data frame where results will be stored
df_sens = DataFrame(parameter = :shoot, minimum = -999., maximum = -999., mode = -999.)


# append the parameters and their distribution values to the data frame
push!(df_sens, [:save_savingsrate, 10, 20, 15])

#push!(df_sens, [:wincf_weightsfactor_sea["USA"], .6, 1, .8])
#wincf_weightsfactor_sea["OECD"], .4, 1.2, .8])
#wincf_weightsfactor_sea["USSR"], .2, .6, .4])
#wincf_weightsfactor_sea["China"], .4, 1.2, .8])
#wincf_weightsfactor_sea["SEAsia"], .4, 1.2, .8])
#wincf_weightsfactor_sea["Africa"], .4, .8, .6])
#wincf_weightsfactor_sea["LatAmerica"], .4, .8, .6])

push!(df_sens, [:automult_autonomouschange, 0.5, 0.8, 0.65])  #components: AdaptationCosts, AbatementCosts

#The following RVs are divided into blocks by component

# CO2cycle
push!(df_sens, [:air_CO2fractioninatm, 57, 67, 62])
push!(df_sens, [:res_CO2atmlifetime, 50, 100, 70])
#ccf_CO2feedback, 0, 0, 0]) # only usable if lb <> ub
push!(df_sens, [:ccfmax_maxCO2feedback, 10, 30, 20])
push!(df_sens, [:stay_fractionCO2emissionsinatm, 0.25,0.35,0.3])
push!(df_sens, [:ce_0_basecumCO2emissions, 1830000, 2240000, 2040000])
push!(df_sens, [:a1_percentco2oceanlong,  4.3,	41.6, 23.0])
push!(df_sens, [:a2_percentco2oceanshort, 23.1, 30.1, 26.6])
push!(df_sens, [:a3_percentco2land, 11.4, 42.5, 27.0])
push!(df_sens, [:t1_timeco2oceanlong, 248.9, 376.2, 312.5])
push!(df_sens, [:t2_timeco2oceanshort, 25.9, 43.9, 34.9])
push!(df_sens, [:t3_timeco2land, 2.8, 5.7, 4.3])
push!(df_sens, [:rt_g0_baseglobaltemp, 0.903, 0.989, 0.946])

# SulphateForcing
push!(df_sens, [:d_sulphateforcingbase, -0.8, -0.2, -0.4])
push!(df_sens, [:ind_slopeSEforcing_indirect, -0.8, 0, -0.4])

# ClimateTemperature
push!(df_sens, [:frt_warminghalflife, 10, 55, 20])        # from PAGE-ICE v6.2 documentation
push!(df_sens, [:tcr_transientresponse, 0.8, 2.7, 1.8])   # from PAGE-ICE v6.2 documentation
#push!(df_sens, [:ampf_amplification["EU"], 1.05, 1.53, 1.23])
#push!(df_sens, [:ampf_amplification["USA"], 1.16, 1.54, 1.32])
#push!(df_sens, [:ampf_amplification["OECD"], 1.14, 1.31, 1.21])
#push!(df_sens, [:ampf_amplification["USSR"], 1.41, 1.9, 1.64])
#push!(df_sens, [:ampf_amplification["China"], 1, 1.3, 1.21])
#push!(df_sens, [:ampf_amplification["SEAsia"], 0.84, 1.15, 1.04])
#push!(df_sens, [:ampf_amplification["Africa"], 0.99, 1.42, 1.22])
#push!(df_sens, [:ampf_amplification["LatAmerica"], 0.9, 1.18, 1.04])

# SeaLevelRise
push!(df_sens, [:s0_initialSL, 0.17, 0.21, 0.19])                             # taken from PAGE-ICE v6.20 default
push!(df_sens, [:sltemp_SLtemprise, 0.7, 3., 1.5])                            # median sensitivity to GMST changes
push!(df_sens, [:sla_SLbaselinerise, 0.5, 1.5, 1.])                      # fat-tailed distribution of time constant T_sl, sea level response time, from mode=362, mean = 386

# GDP
push!(df_sens, [:isat0_initialimpactfxnsaturation, 15, 25, 20])

# MarketDamages
push!(df_sens, [:tcal_CalibrationTemp, 2.5, 3.5, 3.])
push!(df_sens, [:iben_MarketInitialBenefit, 0, .3, .1])
push!(df_sens, [:W_MarketImpactsatCalibrationTemp, .2, .8, .5])
push!(df_sens, [:pow_MarketImpactExponent, 1.5, 3, 2])
push!(df_sens, [:ipow_MarketIncomeFxnExponent, -.3, 0, -.1])

# MarketDamagesBurke
push!(df_sens, [:impf_coeff_lin, -0.0139791885347898, -0.0026206307945989, -0.00829990966469437])
push!(df_sens, [:impf_coeff_quadr, -0.000599999506482576, -0.000400007300924579, -0.000500003403703578])

#rtl_abs_0_realizedabstemperature["EU"], 6.76231496767033, 13.482086163781, 10.1222005657257])
#rtl_abs_0_realizedabstemperature["USA"], 9.54210085883826, 17.3151395362191, 13.4286201975287])
#rtl_abs_0_realizedabstemperature["OECD"], 9.07596053028087, 15.0507477943984, 12.0633541623396])
#rtl_abs_0_realizedabstemperature["USSR"], 3.01320548016903, 11.2132204366259, 7.11321295839747])
#rtl_abs_0_realizedabstemperature["China"], 12.2330402806912, 17.7928749427573, 15.0129576117242])
#rtl_abs_0_realizedabstemperature["SEAsia"], 23.3863348263352, 26.5136231383473, 24.9499789823412])
#rtl_abs_0_realizedabstemperature["Africa"], 20.1866940491107, 23.5978086497453, 21.892251349428])
#rtl_abs_0_realizedabstemperature["LatAmerica"], 19.4846849750102, 22.7561130637973, 21.1203990194037])

# NonMarketDamages
push!(df_sens, [:iben_NonMarketInitialBenefit, 0, .2, .05])
push!(df_sens, [:w_NonImpactsatCalibrationTemp, .1, 1, .5])
push!(df_sens, [:pow_NonMarketExponent, 1.5, 3, 2])
push!(df_sens, [:ipow_NonMarketIncomeFxnExponent, -.2, .2, 0])

# SLRDamages
push!(df_sens, [:scal_calibrationSLR, 0.45, 0.55, .5])
#iben_SLRInitialBenefit, 0, 0, 0]) # only usable if lb <> ub
push!(df_sens, [:W_SatCalibrationSLR, .5, 1.5, 1])
push!(df_sens, [:pow_SLRImpactFxnExponent, .5, 1, .7])
push!(df_sens, [:ipow_SLRIncomeFxnExponent, -.4, -.2, -.3])

# Discountinuity
push!(df_sens, [:tdis_tolerabilitydisc, 1, 2, 1.5])
push!(df_sens, [:pdis_probability, 10, 30, 20])
push!(df_sens, [:wdis_gdplostdisc, 1, 5, 3])
push!(df_sens, [:ipow_incomeexponent, -.3, 0, -.1])
push!(df_sens, [:distau_discontinuityexponent, 10, 30, 20])

# EquityWeighting
push!(df_sens, [:civvalue_civilizationvalue, 1e10, 1e11, 5e10])
push!(df_sens, [:ptp_timepreference, 0.1,2,1])
push!(df_sens, [:emuc_utilityconvexity, 0.5,2,1])

# AbatementCosts
push!(df_sens, [:AbatementCostParametersCO2_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, -50,6.0,-22])
push!(df_sens, [:AbatementCostParametersCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, -67,6.0,-30])
push!(df_sens, [:AbatementCostParametersN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, -20,6.0,-7.0])
push!(df_sens, [:AbatementCostParametersLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, -50,50,0])

push!(df_sens, [:AbatementCostParametersCO2_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, 0,40,20])
push!(df_sens, [:AbatementCostParametersCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, 0,20,10])
push!(df_sens, [:AbatementCostParametersN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, 0,20,10])
push!(df_sens, [:AbatementCostParametersLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, 0,20,10])

push!(df_sens, [:AbatementCostParametersCO2_c0init_MostNegativeCostCutbackinBaseYear, -400,-100,-200])
push!(df_sens, [:AbatementCostParametersCH4_c0init_MostNegativeCostCutbackinBaseYear, -8000,-1000,-4000])
push!(df_sens, [:AbatementCostParametersN2O_c0init_MostNegativeCostCutbackinBaseYear, -15000,0,-7000])
push!(df_sens, [:AbatementCostParametersLin_c0init_MostNegativeCostCutbackinBaseYear, -400,-100,-200])

push!(df_sens, [:AbatementCostParametersCO2_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, 60,80,70])
push!(df_sens, [:AbatementCostParametersCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, 35,70,50])
push!(df_sens, [:AbatementCostParametersN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, 35,70,50])
push!(df_sens, [:AbatementCostParametersLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, 60,80,70])

push!(df_sens, [:AbatementCostParametersCO2_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, 100,700,400])
push!(df_sens, [:AbatementCostParametersCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, 3000,10000,6000])
push!(df_sens, [:AbatementCostParametersN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, 2000,60000,20000])
push!(df_sens, [:AbatementCostParametersLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, 100,600,300])

push!(df_sens, [:AbatementCostParametersCO2_ies_InitialExperienceStockofCutbacks, 100000,200000,150000])
push!(df_sens, [:AbatementCostParametersCH4_ies_InitialExperienceStockofCutbacks, 1500,2500,2000])
push!(df_sens, [:AbatementCostParametersN2O_ies_InitialExperienceStockofCutbacks, 30,80,50])
push!(df_sens, [:AbatementCostParametersLin_ies_InitialExperienceStockofCutbacks, 1500,2500,2000])

#the following variables need to be set, but set the same in all 4 abatement cost components
#note that for these regional variables, the first region is the focus region (EU]), which is set in the preceding code, and so is always one for these variables

#emitf_uncertaintyinBAUemissfactor["USA"], 0.8,1.2,1.0])
#emitf_uncertaintyinBAUemissfactor["OECD"], 0.8,1.2,1.0])
#emitf_uncertaintyinBAUemissfactor["USSR"], 0.65,1.35,1.0])
#emitf_uncertaintyinBAUemissfactor["China"], 0.5,1.5,1.0])
#emitf_uncertaintyinBAUemissfactor["SEAsia"], 0.5,1.5,1.0])
#emitf_uncertaintyinBAUemissfactor["Africa"], 0.5,1.5,1.0])
#emitf_uncertaintyinBAUemissfactor["LatAmerica"], 0.5,1.5,1.0])

#q0f_negativecostpercentagefactor["USA"], 0.75,1.5,1.0])
#q0f_negativecostpercentagefactor["OECD"], 0.75,1.25,1.0])
#q0f_negativecostpercentagefactor["USSR"], 0.4,1.0,0.7])
#q0f_negativecostpercentagefactor["China"], 0.4,1.0,0.7])
#q0f_negativecostpercentagefactor["SEAsia"], 0.4,1.0,0.7])
#q0f_negativecostpercentagefactor["Africa"], 0.4,1.0,0.7])
#q0f_negativecostpercentagefactor["LatAmerica"], 0.4,1.0,0.7])

#cmaxf_maxcostfactor["USA"], 0.8,1.2,1.0])
#cmaxf_maxcostfactor["OECD"], 1.0,1.5,1.2])
#cmaxf_maxcostfactor["USSR"], 0.4,1.0,0.7])
#cmaxf_maxcostfactor["China"], 0.8,1.2,1.0])
#cmaxf_maxcostfactor["SEAsia"], 1,1.5,1.2])
#cmaxf_maxcostfactor["Africa"], 1,1.5,1.2])
#cmaxf_maxcostfactor["LatAmerica"], 0.4,1.0,0.7])

push!(df_sens, [:q0propmult_cutbacksatnegativecostinfinalyear, 0.3,1.2,0.7])
push!(df_sens, [:qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear, 1,1.5,1.3])
push!(df_sens, [:c0mult_mostnegativecostinfinalyear, 0.5,1.2,0.8])
push!(df_sens, [:curve_below_curvatureofMACcurvebelowzerocost, 0.25,0.8,0.45])
push!(df_sens, [:curve_above_curvatureofMACcurveabovezerocost, 0.1,0.7,0.4])
push!(df_sens, [:cross_experiencecrossoverratio, 0.1,0.3,0.2])
push!(df_sens, [:learn_learningrate, 0.05,0.35,0.2])

# AdaptationCosts
push!(df_sens, [:AdaptiveCostsSeaLevel_cp_costplateau_eu, 0.01, 0.04, 0.02])
push!(df_sens, [:AdaptiveCostsSeaLevel_ci_costimpact_eu, 0.0005, 0.002, 0.001])
push!(df_sens, [:AdaptiveCostsEconomic_cp_costplateau_eu, 0.005, 0.02, 0.01])
push!(df_sens, [:AdaptiveCostsEconomic_ci_costimpact_eu, 0.001, 0.008, 0.003])
push!(df_sens, [:AdaptiveCostsNonEconomic_cp_costplateau_eu, 0.01, 0.04, 0.02])
push!(df_sens, [:AdaptiveCostsNonEconomic_ci_costimpact_eu, 0.002, 0.01, 0.005])

##cf_costregional["USA"], 0.6, 1, 0.8])
#cf_costregional["OECD"], 0.4, 1.2, 0.8])
#cf_costregional["USSR"], 0.2, 0.6, 0.4])
#cf_costregional["China"], 0.4, 1.2, 0.8])
#cf_costregional["SEAsia"], 0.4, 1.2, 0.8])
#cf_costregional["Africa"], 0.4, 0.8, 0.6])
#cf_costregional["LatAmerica"], 0.4, 0.8, 0.6])


########################################################################
###################### SENSITIVITY ANALYSIS ############################
########################################################################

# add empty columns for mean, sd, scc_change, absolute-value scc_change and distribution type
df_sens[:mean] = -999.
df_sens[:sd] = -999.
df_sens[:scc_change] = -999.
df_sens[:scc_change_abs] = -999.
df_sens[:distributiontype] = "Triangular"

# calculate mean and sd
df_sens[:mean] = (df_sens[:minimum] .+ df_sens[:maximum] .+ df_sens[:mode]) / 3
df_sens[:sd] = (((df_sens[:minimum] .- df_sens[:maximum]).^2 .+
                    (df_sens[:maximum] .- df_sens[:mode]).^2 .+ (df_sens[:minimum] .- df_sens[:mode]).^2 ) / 36 ).^0.5

# drop the placeholder row
df_sens = df_sens[df_sens[:minimum] .!= -999., :]

# add non-triangular parameters
push!(df_sens, [:sltau_SLresponsetime, 16.0833333333333333, 24., 0., 16.0833333333333333*24, (16.0833333333333333)^0.5 * 24, -999., -999., "Gamma"])
push!(df_sens, [:rand_discontinuity, 0, 1, 0.5, 0.5, (1-0)/12^0.5, -999., -999., "Uniform"])


# loop through the parameters and recompute
include("getpagefunction.jl")
df_sens[:scc_change_abs] = -999.
reset_masterparameters()

for jj_rownumber in 1:(nrow(df_sens))
    m = getpage()
    run(m)
    global scc_main = compute_scc(m, year = 2020)

    update_param!(m, df_sens[:parameter][jj_rownumber], df_sens[:mean][jj_rownumber] + df_sens[:sd][jj_rownumber])
    run(m)

    global scc_new = compute_scc(m, year = 2020)

    df_sens[:scc_change][jj_rownumber] = scc_new - scc_main
    df_sens[:scc_change_abs][jj_rownumber] = abs(scc_new - scc_main)

end

# sort the data frame according to the absolute value of SCC change
sort!(df_sens, :scc_change_abs, rev = true)

# write out the results
CSV.write(string(dir_output, "MimiPageSensitivitySCC.csv"), df_sens)
