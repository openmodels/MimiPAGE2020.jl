# read in the model module
include("../src/PAGE-2020.jl")

# call additional packages
using Distributions
using Mimi
using Statistics
using DataFrames
using CSV

# define an output directory where the sensitivity analysis results will be stored
dir_output = joinpath(@__DIR__, "../output/")

# define the model regions in the right order (copy-pasted from main_model.jl)
page_regions = ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"]

# initiate a Data Frame that will store sensitivity results
df_sens = DataFrame(parameter = ":placeholder", distribution = [TriangularDist(-99, -90, -95), Uniform(-99, -95),
                                                                Gamma(90, 9)],
                        param_mean = -999., param_std = -999.,
                        scc_for_default = -999., scc_pushed = -999., scc_impact = -999., scc_impact_abs = -999.,
                        scc_pushed_neg = -999., scc_impact_neg = -999., scc_impact_neg_abs = -999.
)

# define a function that pushes parameters by one standard deviation and stores the SCC impact and key summary stats into a vector
scc_for_1std_push = function(parameter,
                             distribution,
                             manual_default::Union{Float64,Nothing}=nothing,
                             year::Union{Int,Nothing}=2020
                             )
        m = PAGE2020.getpage()
        Mimi.run(m)

        if isnothing(manual_default)
                default_value = mean(distribution)
        else
                default_value = manual_default
        end

        Mimi.set_param!(m, parameter, default_value)
        run(m)
        scc_for_default = PAGE2020.compute_scc(m, year = year)

        Mimi.update_param!(m, parameter, default_value + std(distribution))
        Mimi.run(m)
        scc_pushed = PAGE2020.compute_scc(m, year = year)

        Mimi.update_param!(m, parameter, default_value - std(distribution))
        Mimi.run(m)
        scc_pushed_neg = PAGE2020.compute_scc(m, year = year)

        [string(parameter), distribution, default_value, std(distribution),
        scc_for_default, scc_pushed, scc_pushed - scc_for_default, abs(scc_pushed - scc_for_default),
        scc_pushed_neg, scc_pushed_neg - scc_for_default, abs(scc_pushed_neg - scc_for_default)]
end

# define a function for parameters that have identical names in different components (across abatement cost and adaptation cost components)
scc_for_1std_push_abatement = function(component,
                                        parameter,
                                        distribution,
                                        manual_default::Union{Float64,Nothing}=nothing,
                                        year::Union{Int,Nothing}=2020
                                        )
        m = PAGE2020.getpage()
        Mimi.run(m)

        if isnothing(manual_default)
                default_value = mean(distribution)
        else
                default_value = manual_default
        end

        Mimi.set_param!(m, component, parameter, default_value)
        Mimi.run(m)
        scc_for_default = PAGE2020.compute_scc(m, year = year)

        m = PAGE2020.getpage()
        Mimi.set_param!(m, component, parameter, default_value + std(distribution))
        Mimi.run(m)
        scc_pushed = PAGE2020.compute_scc(m, year = year)

        m = PAGE2020.getpage()
        Mimi.set_param!(m, component, parameter, default_value - std(distribution))
        Mimi.run(m)
        scc_pushed_neg = PAGE2020.compute_scc(m, year = year)

        [string(component, "_", parameter), distribution, default_value, std(distribution),
        scc_for_default, scc_pushed, scc_pushed - scc_for_default, abs(scc_pushed - scc_for_default),
        scc_pushed_neg, scc_pushed_neg - scc_for_default, abs(scc_pushed_neg - scc_for_default)]
end

# write a function for all parameters that have region-specific entries
# note: although component is an input, this is only used to read out the region-specific defaults. the parameter change is applied to the whole model
scc_for_1std_push_regional = function(component,
                                        parameter,
                                        region_shocked,
                                        distribution,
                                        manual_default::Union{Float64,Nothing}=nothing,
                                        year::Union{Int,Nothing}=2020
                                        )
        m = PAGE2020.getpage()
        Mimi.run(m)

        if isnothing(manual_default)
                default_value = mean(distribution)
        else
                default_value = manual_default
        end

        param_to_modify = m[component, parameter]
        position_region_shocked = findall(x -> x == region_shocked, page_regions)
        param_to_modify[position_region_shocked] .= default_value

        Mimi.set_param!(m, parameter, param_to_modify)
        Mimi.run(m)
        scc_for_default = PAGE2020.compute_scc(m, year = year)

        param_to_modify[position_region_shocked] .= default_value + std(distribution)

        Mimi.update_param!(m, parameter, param_to_modify)
        Mimi.run(m)
        scc_pushed = PAGE2020.compute_scc(m, year = year)

        param_to_modify[position_region_shocked] .= default_value - std(distribution)

        Mimi.update_param!(m, parameter, param_to_modify)
        Mimi.run(m)
        scc_pushed_neg = PAGE2020.compute_scc(m, year = year)

        [string(parameter, "_", region_shocked), distribution, default_value, std(distribution),
        scc_for_default, scc_pushed, scc_pushed - scc_for_default, abs(scc_pushed - scc_for_default),
        scc_pushed_neg, scc_pushed_neg - scc_for_default, abs(scc_pushed_neg - scc_for_default)]
end

## re-calculate the SCC for a standard deviation push and save the results into the df_sens DataFrame
# distribution definitions are copy-pasted from mcs.jl
        # save_savingsrate = TriangularDist(10, 20, 15) # components: MarketDamages, MarketDamagesBurke, NonMarketDamages. GDP, SLRDamages
        push!(df_sens, scc_for_1std_push(:save_savingsrate, TriangularDist(10, 20, 15)))

        #tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.) # components: MarketDamages, NonMarketDamages, SLRDamages, Discountinuity
        push!(df_sens, scc_for_1std_push(:tcal_CalibrationTemp, TriangularDist(2.5, 3.5, 3.)))

        #wincf_weightsfactor_sea["USA"] = TriangularDist(.6, 1, .8) # components: SLRDamages, Discountinuity (weights for market and nonmarket are non-stochastic and uniformly 1)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "USA", TriangularDist(.6, 1, .8))

        #wincf_weightsfactor_sea["OECD"] = TriangularDist(.4, 1.2, .8)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "OECD", TriangularDist(.4, 1.2, .8))

        #wincf_weightsfactor_sea["USSR"] = TriangularDist(.2, .6, .4)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "USSR", TriangularDist(.2, .6, .4))

        #wincf_weightsfactor_sea["China"] = TriangularDist(.4, 1.2, .8)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "China", TriangularDist(.4, 1.2, .8))

        #wincf_weightsfactor_sea["SEAsia"] = TriangularDist(.4, 1.2, .8)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "SEAsia", TriangularDist(.4, 1.2, .8))

        #wincf_weightsfactor_sea["Africa"] = TriangularDist(.4, .8, .6)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "Africa", TriangularDist(.4, .8, .6))

        #wincf_weightsfactor_sea["LatAmerica"] = TriangularDist(.4, .8, .6)
        scc_for_1std_push_regional(:SLRDamages, :wincf_weightsfactor_sea, "LatAmerica", TriangularDist(.4, .8, .6))

        # automult_autonomoustechchange = TriangularDist(0.5, 0.8, 0.65)  # components: AdaptationCosts, AbatementCosts
        push!(df_sens, scc_for_1std_push(:automult_autonomoustechchange, TriangularDist(0.5, 0.8, 0.65)))

        # CO2cycle
        # air_CO2fractioninatm = TriangularDist(57, 67, 62)
        push!(df_sens, scc_for_1std_push(:air_CO2fractioninatm, TriangularDist(57, 67, 62)))

        # res_CO2atmlifetime = TriangularDist(50, 100, 70)
        push!(df_sens, scc_for_1std_push(:res_CO2atmlifetime, TriangularDist(50, 100, 70)))

        # ccf_CO2feedback = TriangularDist(0, 0, 0) # only usable if lb <> ub          # note: this parameter is already commented out in the mcs.jl file (as of 20/03/2021)

        # ccfmax_maxCO2feedback = TriangularDist(10, 30, 20)
        push!(df_sens, scc_for_1std_push(:ccfmax_maxCO2feedback, TriangularDist(10, 30, 20)))

        # stay_fractionCO2emissionsinatm = TriangularDist(0.25, 0.35, 0.3)
        push!(df_sens, scc_for_1std_push(:stay_fractionCO2emissionsinatm, TriangularDist(0.25, 0.35, 0.3), 0.2341802168612297))

        # ce_0_basecumCO2emissions = TriangularDist(1830000, 2240000, 2040000)
        push!(df_sens, scc_for_1std_push(:ce_0_basecumCO2emissions, TriangularDist(1830000, 2240000, 2040000)))

        # a1_percentco2oceanlong = TriangularDist(4.3,	41.6, 23.0)
        push!(df_sens, scc_for_1std_push(:a1_percentco2oceanlong, TriangularDist(4.3,	41.6, 23.0)))

        # a2_percentco2oceanshort = TriangularDist(23.1, 30.1, 26.6)
        push!(df_sens, scc_for_1std_push(:a2_percentco2oceanshort, TriangularDist(23.1, 30.1, 26.6)))

        # a3_percentco2land = TriangularDist(11.4, 42.5, 27.0)
        push!(df_sens, scc_for_1std_push(:a3_percentco2land,  TriangularDist(11.4, 42.5, 27.0)))

        # t1_timeco2oceanlong = TriangularDist(248.9, 376.2, 312.5)
        push!(df_sens, scc_for_1std_push(:t1_timeco2oceanlong, TriangularDist(248.9, 376.2, 312.5)))

        # t2_timeco2oceanshort = TriangularDist(25.9, 43.9, 34.9)
        push!(df_sens, scc_for_1std_push(:t2_timeco2oceanshort, TriangularDist(25.9, 43.9, 34.9)))

        # t3_timeco2land = TriangularDist(2.8, 5.7, 4.3)
        push!(df_sens, scc_for_1std_push(:t3_timeco2land, TriangularDist(2.8, 5.7, 4.3)))

        # rt_g0_baseglobaltemp = TriangularDist(0.903, 0.989, 0.946)
        push!(df_sens, scc_for_1std_push(:rt_g0_baseglobaltemp, TriangularDist(0.903, 0.989, 0.946)))


        # SiBCASA Permafrost
        # perm_sib_af = TriangularDist(1.42609149897258, 2.32504747848815, 1.87556948873036)
        push!(df_sens, scc_for_1std_push(:perm_sib_af, TriangularDist(1.42609149897258, 2.32504747848815, 1.87556948873036)))

        # perm_sib_sens_c_co2 = TriangularDist(28191.1555428869, 35688.3253432574, 31939.7404430722)
        push!(df_sens, scc_for_1std_push(:perm_sib_sens_c_co2, TriangularDist(28191.1555428869, 35688.3253432574, 31939.7404430722)))

        # perm_sib_lag_c_co2 = TriangularDist(35.4926669856915, 87.8949041341782, 61.6937855599349)
        push!(df_sens, scc_for_1std_push(:perm_sib_lag_c_co2, TriangularDist(35.4926669856915, 87.8949041341782, 61.6937855599349)))

        # perm_sib_pow_c_co2 = TriangularDist(0.107020247715729, 0.410961185142816, 0.258990716429273)
        push!(df_sens, scc_for_1std_push(:perm_sib_pow_c_co2, TriangularDist(0.107020247715729, 0.410961185142816, 0.258990716429273)))

        # perm_sib_sens_c_ch4 = TriangularDist(1240.3553299183, 3348.11995329232, 2294.23764160531)
        push!(df_sens, scc_for_1std_push(:perm_sib_sens_c_ch4, TriangularDist(1240.3553299183, 3348.11995329232, 2294.23764160531)))

        # perm_sib_lag_c_ch4 = TriangularDist(75.1943160023131, 337.382510123922, 206.288413063117)
        push!(df_sens, scc_for_1std_push(:perm_sib_lag_c_ch4, TriangularDist(75.1943160023131, 337.382510123922, 206.288413063117)))

        # perm_sib_pow_c_ch4 = TriangularDist(-0.108779283732708, 0.610889007954489, 0.25105486211089)
        push!(df_sens, scc_for_1std_push(:perm_sib_pow_c_ch4, TriangularDist(-0.108779283732708, 0.610889007954489, 0.25105486211089)))

        # JULES Permafrost
        # perm_jul_af = TriangularDist(1.70960411816136, 2.16221162526313, 1.93590787171224)
        push!(df_sens, scc_for_1std_push(:perm_jul_af, TriangularDist(1.70960411816136, 2.16221162526313, 1.93590787171224)))

        # perm_jul_sens_c_co2 = TriangularDist(24726.8035695649, 99008.7553497378, 61867.7794596514)
        push!(df_sens, scc_for_1std_push(:perm_jul_sens_c_co2, TriangularDist(24726.8035695649, 99008.7553497378, 61867.7794596514)))

        # perm_jul_lag_c_co2 = TriangularDist(252.558368389676, 834.674343162273, 543.616355775975)
        push!(df_sens, scc_for_1std_push(:perm_jul_lag_c_co2,  TriangularDist(252.558368389676, 834.674343162273, 543.616355775975)))

        # perm_jul_pow_c_co2 = TriangularDist(-0.226045987062471, 1.14010750072118, 0.457030756829357)
        push!(df_sens, scc_for_1std_push(:perm_jul_pow_c_co2, TriangularDist(-0.226045987062471, 1.14010750072118, 0.457030756829357)))

        # perm_jul_ch4_co2_c_ratio = TriangularDist(2.77492291880781, 9.52902519167579, 6.04453870625663)
        push!(df_sens, scc_for_1std_push(:perm_jul_ch4_co2_c_ratio, TriangularDist(2.77492291880781, 9.52902519167579, 6.04453870625663)))


        # SulphateForcing
        # d_sulphateforcingbase = TriangularDist(-0.8, -0.2, -0.4)
        push!(df_sens, scc_for_1std_push(:d_sulphateforcingbase, TriangularDist(-0.8, -0.2, -0.4)))

        # ind_slopeSEforcing_indirect = TriangularDist(-0.8, 0, -0.4)
        push!(df_sens, scc_for_1std_push(:ind_slopeSEforcing_indirect, TriangularDist(-0.8, 0, -0.4)))

        # ClimateTemperature
        # frt_warminghalflife = TriangularDist(10, 55, 20)        # from PAGE-ICE v6.2 documentation
        push!(df_sens, scc_for_1std_push(:frt_warminghalflife, TriangularDist(10, 55, 20)))

        # tcr_transientresponse = TriangularDist(0.8, 2.7, 1.8)   # from PAGE-ICE v6.2 documentation
        push!(df_sens, scc_for_1std_push(:tcr_transientresponse, TriangularDist(0.8, 2.7, 1.8)))

        # alb_emulator_rand = TriangularDist(-1., 1., 0.)
        push!(df_sens, scc_for_1std_push(:alb_emulator_rand, TriangularDist(-1., 1., 0.)))

        #ampf_amplification["EU"] = TriangularDist(1.05, 1.53, 1.23)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "EU", TriangularDist(1.05, 1.53, 1.23)))

        #ampf_amplification["USA"] = TriangularDist(1.16, 1.54, 1.32)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "USA", TriangularDist(1.16, 1.54, 1.32)))

        #ampf_amplification["OECD"] = TriangularDist(1.14, 1.31, 1.21)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "OECD", TriangularDist(1.14, 1.31, 1.21)))

        #ampf_amplification["USSR"] = TriangularDist(1.41, 1.9, 1.64)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "USSR", TriangularDist(1.41, 1.9, 1.64)))

        #ampf_amplification["China"] = TriangularDist(1, 1.3, 1.21)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "China", TriangularDist(1, 1.3, 1.21)))

        #ampf_amplification["SEAsia"] = TriangularDist(0.84, 1.15, 1.04)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "SEAsia", TriangularDist(0.84, 1.15, 1.04)))

        #ampf_amplification["Africa"] = TriangularDist(0.99, 1.42, 1.22)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "Africa", TriangularDist(0.99, 1.42, 1.22)))

        #ampf_amplification["LatAmerica"] = TriangularDist(0.9, 1.18, 1.04)
        push!(df_sens, scc_for_1std_push_regional(:ClimateTemperature, :ampf_amplification, "LatAmerica", TriangularDist(0.9, 1.18, 1.04)))

        # SeaLevelRise
        # s0_initialSL = TriangularDist(0.17, 0.21, 0.19)                             # taken from PAGE-ICE v6.20 default
        push!(df_sens, scc_for_1std_push(:s0_initialSL, TriangularDist(0.17, 0.21, 0.19) ))

        # sltemp_SLtemprise = TriangularDist(0.7, 3., 1.5)                            # median sensitivity to GMST changes
        push!(df_sens, scc_for_1std_push(:sltemp_SLtemprise, TriangularDist(0.7, 3., 1.5)))

        # sla_SLbaselinerise = TriangularDist(0.5, 1.5, 1.)                           # asymptote for pre-industrial
        push!(df_sens, scc_for_1std_push(:sla_SLbaselinerise, TriangularDist(0.5, 1.5, 1.) ))

        # sltau_SLresponsetime = Gamma(16.0833333333333333, 24.)                      # fat-tailed distribution of time constant T_sl, sea level response time, from mode=362, mean = 386
        push!(df_sens, scc_for_1std_push(:sltau_SLresponsetime, Gamma(16.0833333333333333, 24.)  ))

        # GDP
        # isat0_initialimpactfxnsaturation = TriangularDist(15, 25, 20)
        push!(df_sens, scc_for_1std_push(:isat0_initialimpactfxnsaturation, TriangularDist(15, 25, 20)))

        # MarketDamages
        # iben_MarketInitialBenefit = TriangularDist(0, .3, .1)
        push!(df_sens, scc_for_1std_push(:iben_MarketInitialBenefit, TriangularDist(0, .3, .1)))

        # W_MarketImpactsatCalibrationTemp = TriangularDist(.2, .8, .5)
        push!(df_sens, scc_for_1std_push(:W_MarketImpactsatCalibrationTemp, TriangularDist(.2, .8, .5)))

        # pow_MarketImpactExponent = TriangularDist(1.5, 3, 2)
        push!(df_sens, scc_for_1std_push(:pow_MarketImpactExponent, TriangularDist(1.5, 3, 2)))

        # ipow_MarketIncomeFxnExponent = TriangularDist(-.3, 0, -.1)
        push!(df_sens, scc_for_1std_push(:ipow_MarketIncomeFxnExponent, TriangularDist(-.3, 0, -.1)))


        # MarketDamagesBurke
        # impf_coeff_lin = TriangularDist(-0.0139791885347898, -0.0026206307945989, -0.00829990966469437)
        push!(df_sens, scc_for_1std_push(:impf_coeff_lin, TriangularDist(-0.0139791885347898, -0.0026206307945989, -0.00829990966469437)))

        # impf_coeff_quadr = TriangularDist(-0.000599999506482576, -0.000400007300924579, -0.000500003403703578)
        push!(df_sens, scc_for_1std_push(:impf_coeff_quadr, TriangularDist(-0.000599999506482576, -0.000400007300924579, -0.000500003403703578)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["EU"] = TriangularDist(6.76231496767033, 13.482086163781, 10.1222005657257)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "EU", TriangularDist(6.76231496767033, 13.482086163781, 10.1222005657257)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["USA"] = TriangularDist(9.54210085883826, 17.3151395362191, 13.4286201975287)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "USA", TriangularDist(9.54210085883826, 17.3151395362191, 13.4286201975287)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["OECD"] = TriangularDist(9.07596053028087, 15.0507477943984, 12.0633541623396)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "OECD", TriangularDist(9.07596053028087, 15.0507477943984, 12.0633541623396)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["USSR"] = TriangularDist(3.01320548016903, 11.2132204366259, 7.11321295839747)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "USSR", TriangularDist(3.01320548016903, 11.2132204366259, 7.11321295839747)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["China"] = TriangularDist(12.2330402806912, 17.7928749427573, 15.0129576117242)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "China", TriangularDist(12.2330402806912, 17.7928749427573, 15.0129576117242)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["SEAsia"] = TriangularDist(23.3863348263352, 26.5136231383473, 24.9499789823412)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "SEAsia", TriangularDist(23.3863348263352, 26.5136231383473, 24.9499789823412)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["Africa"] = TriangularDist(20.1866940491107, 23.5978086497453, 21.892251349428)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "Africa", TriangularDist(20.1866940491107, 23.5978086497453, 21.892251349428)))

        # MarketDamagesBurke_rtl_abs_0_realizedabstemperature["LatAmerica"] = TriangularDist(19.4846849750102, 22.7561130637973, 21.1203990194037)
        push!(df_sens, scc_for_1std_push_regional(:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature, "LatAmerica", TriangularDist(19.4846849750102, 22.7561130637973, 21.1203990194037)))

        # NonMarketDamages
        # tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.)
        # push!(df_sens, scc_for_1std_push(:tcal_CalibrationTemp, TriangularDist(2.5, 3.5, 3.)))
        # Note: commented out as this is a duplicate from the mcs.jl file and is already featured above

        # iben_NonMarketInitialBenefit = TriangularDist(0, .2, .05)
        push!(df_sens, scc_for_1std_push(:iben_NonMarketInitialBenefit, TriangularDist(0, .2, .05)))

        # w_NonImpactsatCalibrationTemp = TriangularDist(.1, 1, .5)
        push!(df_sens, scc_for_1std_push(:w_NonImpactsatCalibrationTemp, TriangularDist(.1, 1, .5)))

        # pow_NonMarketExponent = TriangularDist(1.5, 3, 2)
        push!(df_sens, scc_for_1std_push(:pow_NonMarketExponent, TriangularDist(1.5, 3, 2)))

        # ipow_NonMarketIncomeFxnExponent = TriangularDist(-.2, .2, 0)
        push!(df_sens, scc_for_1std_push(:ipow_NonMarketIncomeFxnExponent, TriangularDist(-.2, .2, 0)))

        # SLRDamages
        # scal_calibrationSLR = TriangularDist(0.45, 0.55, .5)
        push!(df_sens, scc_for_1std_push(:scal_calibrationSLR, TriangularDist(0.45, 0.55, .5)))

        # iben_SLRInitialBenefit = TriangularDist(0, 0, 0) # only usable if lb <> ub
        # W_SatCalibrationSLR = TriangularDist(.5, 1.5, 1)
        push!(df_sens, scc_for_1std_push(:W_SatCalibrationSLR, TriangularDist(.5, 1.5, 1)))

        # pow_SLRImpactFxnExponent = TriangularDist(.5, 1, .7)
        push!(df_sens, scc_for_1std_push(:pow_SLRImpactFxnExponent, TriangularDist(.5, 1, .7)))

        # ipow_SLRIncomeFxnExponent = TriangularDist(-.4, -.2, -.3)
        push!(df_sens, scc_for_1std_push(:ipow_SLRIncomeFxnExponent, TriangularDist(-.4, -.2, -.3)))

        # Discontinuity
        # rand_discontinuity = Uniform(0, 1)
        push!(df_sens, scc_for_1std_push(:rand_discontinuity, Uniform(0, 1)))
        # note that mode() will return the central value for uniform distribution, i.e. 0.5, which equals the default value of rand_discontinuity

        # tdis_tolerabilitydisc = TriangularDist(1, 2, 1.5)
        push!(df_sens, scc_for_1std_push(:tdis_tolerabilitydisc, TriangularDist(1, 2, 1.5)))

        # pdis_probability = TriangularDist(10, 30, 20)
        push!(df_sens, scc_for_1std_push(:pdis_probability, TriangularDist(10, 30, 20)))

        # wdis_gdplostdisc = TriangularDist(1, 5, 3)
        push!(df_sens, scc_for_1std_push(:wdis_gdplostdisc, TriangularDist(1, 5, 3)))

        # ipow_incomeexponent = TriangularDist(-.3, 0, -.1)
        push!(df_sens, scc_for_1std_push(:ipow_incomeexponent, TriangularDist(-.3, 0, -.1)))

        # distau_discontinuityexponent = TriangularDist(10, 30, 20)
        push!(df_sens, scc_for_1std_push(:distau_discontinuityexponent, TriangularDist(10, 30, 20)))

        # EquityWeighting
        # civvalue_civilizationvalue = TriangularDist(1e10, 1e11, 5e10)
        push!(df_sens, scc_for_1std_push(:civvalue_civilizationvalue, TriangularDist(1e10, 1e11, 5e10)))

        # ptp_timepreference = TriangularDist(0.1, 2, 1)
        push!(df_sens, scc_for_1std_push(:ptp_timepreference, TriangularDist(0.1, 2, 1)))

        # emuc_utilityconvexity = TriangularDist(0.5, 2, 1)
        push!(df_sens, scc_for_1std_push(:emuc_utilityconvexity, TriangularDist(0.5, 2, 1)))

        # AbatementCosts
        # AbatementCostParametersCO2_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50, 6.0, -22)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCO2, :emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, TriangularDist(-50, 6.0, -22)))

        # AbatementCostParametersCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-67, 6.0, -30)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCH4, :emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, TriangularDist(-67, 6.0, -30)))

        # AbatementCostParametersN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-20, 6.0, -7.0)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersN2O, :emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, TriangularDist(-20, 6.0, -7.0)))

        # AbatementCostParametersLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50, 50, 0)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersLin, :emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear, TriangularDist(-50, 50, 0)))

        # AbatementCostParametersCO2_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 40, 20)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCO2, :q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, TriangularDist(0, 40, 20)))

        # AbatementCostParametersCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCH4, :q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, TriangularDist(0, 20, 10)))

        # AbatementCostParametersN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersN2O, :q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, TriangularDist(0, 20, 10)))

        # AbatementCostParametersLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersLin, :q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear, TriangularDist(0, 20, 10)))

        # AbatementCostParametersCO2_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400, -100, -200)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCO2, :c0init_MostNegativeCostCutbackinBaseYear, TriangularDist(-400, -100, -200)))

        # AbatementCostParametersCH4_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-8000, -1000, -4000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCH4, :c0init_MostNegativeCostCutbackinBaseYear, TriangularDist(-8000, -1000, -4000)))

        # AbatementCostParametersN2O_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-15000, 0, -7000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersN2O, :c0init_MostNegativeCostCutbackinBaseYear, TriangularDist(-15000, 0, -7000)))

        # AbatementCostParametersLin_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400, -100, -200)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersLin, :c0init_MostNegativeCostCutbackinBaseYear, TriangularDist(-400, -100, -200)))

        # AbatementCostParametersCO2_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60, 80, 70)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCO2, :qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, TriangularDist(60, 80, 70)))

        # AbatementCostParametersCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35, 70, 50)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCH4, :qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, TriangularDist(35, 70, 50)))

        # AbatementCostParametersN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35, 70, 50)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersN2O, :qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, TriangularDist(35, 70, 50)))

        # AbatementCostParametersLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60, 80, 70)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersLin, :qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear, TriangularDist(60, 80, 70)))

        # AbatementCostParametersCO2_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100, 700, 400)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCO2, :cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, TriangularDist(100, 700, 400)))

        # AbatementCostParametersCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(3000, 10000, 6000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCH4, :cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, TriangularDist(3000, 10000, 6000)))

        # AbatementCostParametersN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(2000, 60000, 20000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersN2O, :cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, TriangularDist(2000, 60000, 20000)))

        # AbatementCostParametersLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100, 600, 300)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersLin, :cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear, TriangularDist(100, 600, 300)))

        # AbatementCostParametersCO2_ies_InitialExperienceStockofCutbacks = TriangularDist(100000, 200000, 150000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCO2, :ies_InitialExperienceStockofCutbacks, TriangularDist(100000, 200000, 150000)))

        # AbatementCostParametersCH4_ies_InitialExperienceStockofCutbacks = TriangularDist(1500, 2500, 2000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersCH4, :ies_InitialExperienceStockofCutbacks, TriangularDist(1500, 2500, 2000)))

        # AbatementCostParametersN2O_ies_InitialExperienceStockofCutbacks = TriangularDist(30, 80, 50)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersN2O, :ies_InitialExperienceStockofCutbacks, TriangularDist(30, 80, 50)))

        # AbatementCostParametersLin_ies_InitialExperienceStockofCutbacks = TriangularDist(1500, 2500, 2000)
        push!(df_sens, scc_for_1std_push_abatement(:AbatementCostParametersLin, :ies_InitialExperienceStockofCutbacks, TriangularDist(1500, 2500, 2000)))


        # the following variables need to be set, but set the same in all 4 abatement cost components
        # note that for these regional variables, the first region is the focus region (EU), which is set in the preceding code, and so is always one for these variables

        # emitf_uncertaintyinBAUemissfactor["USA"] = TriangularDist(0.8, 1.2, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "USA", TriangularDist(0.8, 1.2, 1.0)))
        # Note: the component input for the function is only used to extract the default values (which should be identical for the four components where the parameter occur)

        # emitf_uncertaintyinBAUemissfactor["OECD"] = TriangularDist(0.8, 1.2, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "OECD", TriangularDist(0.8, 1.2, 1.0)))

        # emitf_uncertaintyinBAUemissfactor["USSR"] = TriangularDist(0.65, 1.35, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "USSR", TriangularDist(0.65, 1.35, 1.0)))

        # emitf_uncertaintyinBAUemissfactor["China"] = TriangularDist(0.5, 1.5, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "China", TriangularDist(0.5, 1.5, 1.0)))

        # emitf_uncertaintyinBAUemissfactor["SEAsia"] = TriangularDist(0.5, 1.5, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "SEAsia", TriangularDist(0.5, 1.5, 1.0)))

        # emitf_uncertaintyinBAUemissfactor["Africa"] = TriangularDist(0.5, 1.5, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "Africa", TriangularDist(0.5, 1.5, 1.0)))

        # emitf_uncertaintyinBAUemissfactor["LatAmerica"] = TriangularDist(0.5, 1.5, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :emitf_uncertaintyinBAUemissfactor, "LatAmerica", TriangularDist(0.5, 1.5, 1.0)))


        # q0f_negativecostpercentagefactor["USA"] = TriangularDist(0.75, 1.5, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "USA", TriangularDist(0.75, 1.5, 1.0)))

        # q0f_negativecostpercentagefactor["OECD"] = TriangularDist(0.75, 1.25, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "OECD", TriangularDist(0.75, 1.25, 1.0)))

        # q0f_negativecostpercentagefactor["USSR"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "USSR", TriangularDist(0.4, 1.0, 0.7)))

        # q0f_negativecostpercentagefactor["China"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "China", TriangularDist(0.4, 1.0, 0.7)))

        # q0f_negativecostpercentagefactor["SEAsia"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "SEAsia", TriangularDist(0.4, 1.0, 0.7)))

        # q0f_negativecostpercentagefactor["Africa"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "Africa", TriangularDist(0.4, 1.0, 0.7)))

        # q0f_negativecostpercentagefactor["LatAmerica"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :q0f_negativecostpercentagefactor, "LatAmerica",  TriangularDist(0.4, 1.0, 0.7)))


        # cmaxf_maxcostfactor["USA"] = TriangularDist(0.8, 1.2, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "USA",  TriangularDist(0.8, 1.2, 1.0)))

        # cmaxf_maxcostfactor["OECD"] = TriangularDist(1.0, 1.5, 1.2)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "OECD",  TriangularDist(1.0, 1.5, 1.2)))

        # cmaxf_maxcostfactor["USSR"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "USSR",  TriangularDist(0.4, 1.0, 0.7)))

        # cmaxf_maxcostfactor["China"] = TriangularDist(0.8, 1.2, 1.0)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "China",  TriangularDist(0.8, 1.2, 1.0)))

        # cmaxf_maxcostfactor["SEAsia"] = TriangularDist(1, 1.5, 1.2)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "SEAsia",  TriangularDist(1, 1.5, 1.2)))

        # cmaxf_maxcostfactor["Africa"] = TriangularDist(1, 1.5, 1.2)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "Africa",  TriangularDist(1, 1.5, 1.2)))

        # cmaxf_maxcostfactor["LatAmerica"] = TriangularDist(0.4, 1.0, 0.7)
        push!(df_sens, scc_for_1std_push_regional(:AbatementCostParametersCO2, :cmaxf_maxcostfactor, "LatAmerica", TriangularDist(0.4, 1.0, 0.7)))


        # q0propmult_cutbacksatnegativecostinfinalyear = TriangularDist(0.3, 1.2, 0.7)
        push!(df_sens, scc_for_1std_push(:q0propmult_cutbacksatnegativecostinfinalyear, TriangularDist(0.3, 1.2, 0.7)))

        # qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear = TriangularDist(1, 1.5, 1.3)
        push!(df_sens, scc_for_1std_push(:qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear, TriangularDist(1, 1.5, 1.3)))

        # c0mult_mostnegativecostinfinalyear = TriangularDist(0.5, 1.2, 0.8)
        push!(df_sens, scc_for_1std_push(:c0mult_mostnegativecostinfinalyear, TriangularDist(0.5, 1.2, 0.8)))

        # curve_below_curvatureofMACcurvebelowzerocost = TriangularDist(0.25, 0.8, 0.45)
        push!(df_sens, scc_for_1std_push(:curve_below_curvatureofMACcurvebelowzerocost, TriangularDist(0.25, 0.8, 0.45)))

        # curve_above_curvatureofMACcurveabovezerocost = TriangularDist(0.1, 0.7, 0.4)
        push!(df_sens, scc_for_1std_push(:curve_above_curvatureofMACcurveabovezerocost, TriangularDist(0.1, 0.7, 0.4)))

        # cross_experiencecrossoverratio = TriangularDist(0.1, 0.3, 0.2)
        push!(df_sens, scc_for_1std_push(:cross_experiencecrossoverratio, TriangularDist(0.1, 0.3, 0.2)))

        # learn_learningrate = TriangularDist(0.05, 0.35, 0.2)
        push!(df_sens, scc_for_1std_push(:learn_learningrate, TriangularDist(0.05, 0.35, 0.2)))

        # AdaptationCosts
        # AdaptiveCostsSeaLevel_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
        push!(df_sens, scc_for_1std_push_abatement(:AdaptiveCostsSeaLevel, :cp_costplateau_eu, TriangularDist(0.01, 0.04, 0.02)))

        # AdaptiveCostsSeaLevel_ci_costimpact_eu = TriangularDist(0.0005, 0.002, 0.001)
        push!(df_sens, scc_for_1std_push_abatement(:AdaptiveCostsSeaLevel, :ci_costimpact_eu, TriangularDist(0.0005, 0.002, 0.001)))

        # AdaptiveCostsEconomic_cp_costplateau_eu = TriangularDist(0.005, 0.02, 0.01)
        push!(df_sens, scc_for_1std_push_abatement(:AdaptiveCostsEconomic, :cp_costplateau_eu, TriangularDist(0.005, 0.02, 0.01)))

        # AdaptiveCostsEconomic_ci_costimpact_eu = TriangularDist(0.001, 0.008, 0.003)
        push!(df_sens, scc_for_1std_push_abatement(:AdaptiveCostsEconomic, :ci_costimpact_eu, TriangularDist(0.001, 0.008, 0.003)))

        # AdaptiveCostsNonEconomic_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
        push!(df_sens, scc_for_1std_push_abatement(:AdaptiveCostsNonEconomic, :cp_costplateau_eu, TriangularDist(0.01, 0.04, 0.02)))

        # AdaptiveCostsNonEconomic_ci_costimpact_eu = TriangularDist(0.002, 0.01, 0.005)
        push!(df_sens, scc_for_1std_push_abatement(:AdaptiveCostsNonEconomic, :ci_costimpact_eu, TriangularDist(0.002, 0.01, 0.005)))


        # cf_costregional["USA"] = TriangularDist(0.6, 1, 0.8)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "USA", TriangularDist(0.6, 1, 0.8)))

        # cf_costregional["OECD"] = TriangularDist(0.4, 1.2, 0.8)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "OECD", TriangularDist(0.4, 1.2, 0.8)))

        # cf_costregional["USSR"] = TriangularDist(0.2, 0.6, 0.4)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "USSR", TriangularDist(0.2, 0.6, 0.4)))

        # cf_costregional["China"] = TriangularDist(0.4, 1.2, 0.8)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "China", TriangularDist(0.4, 1.2, 0.8)))

        # cf_costregional["SEAsia"] = TriangularDist(0.4, 1.2, 0.8)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "SEAsia", TriangularDist(0.4, 1.2, 0.8)))

        # cf_costregional["Africa"] = TriangularDist(0.4, 0.8, 0.6)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "Africa", TriangularDist(0.4, 0.8, 0.6)))

        # cf_costregional["LatAmerica"] = TriangularDist(0.4, 0.8, 0.6)
        push!(df_sens, scc_for_1std_push_regional(:AdaptiveCostsSeaLevel, :cf_costregional, "LatAmerica", TriangularDist(0.4, 0.8, 0.6)))


# sort the data frame according to the absolute value of SCC change
sort!(df_sens, :scc_impact_abs, rev = true)

# remove the placeholder rows
df_sens = df_sens[df_sens[!, :param_mean] .!= -999., :]

# write out the results
CSV.write(string(dir_output, "MimiPageSensitivitySCC.csv"), df_sens)
