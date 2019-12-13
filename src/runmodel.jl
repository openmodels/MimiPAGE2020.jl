################################################################################
###################### DEFINE MASTER PARAMETERS FOR THIS FILE ##################
################################################################################

using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random
using StatsBase
using Statistics

include("main_model.jl")

# define the model regions in the order that Mimi returns stuff
myregions = ["EU", "USA", "Other OECD","Former USSR","China","Southeast Asia","Africa","Latin America"]
myyears = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]

# define the output directory
dir_output = "C:/Users/nasha/Documents/GitHub/damage-regressions/data/mimi-page-output_Dec19/"

# define number of Monte Carlo runs
global numberofmontecarlo = 10^4
global numberofmontecarlo_sub = trunc(Int, numberofmontecarlo / 1)

# define the seed
global masterseed = 2

# define the pulse size
global scc_pulse_size = 75000.

################################################################################
###################### EXTRACT STATIC SCENARIO STUFF ###########################
################################################################################

for jj_scen in ["RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    m = getpage(jj_scen)
    run(m)

    if jj_scen == "RCP4.5 & SSP2"
        # baseline GDP and percap consumption
        writedlm(string(dir_output, "gdp_0.csv"), hcat(myregions, m[:GDP, :gdp_0]), ",")
        writedlm(string(dir_output, "cons_percap_consumption_0.csv"), hcat(myregions, m[:GDP, :cons_percap_consumption_0]), ",")
        writedlm(string(dir_output, "rtl_abs_0_realizedabstemperature.csv"), hcat(myregions, m[:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature]), ",")
    end

    # export variables which depend only on the scenario
    writedlm(string(dir_output, "rtl_realizedtemperature_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:ClimateTemperature, :rtl_realizedtemperature]]), ",")
    writedlm(string(dir_output, "rtl_realizedtemperature_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:ClimateTemperature, :rtl_realizedtemperature]]), ",")
    writedlm(string(dir_output, "rt_g_globaltemperature_scen", jj_scen, ".csv"), hcat(myyears, m[:ClimateTemperature, :rt_g_globaltemperature]), ",")
    writedlm(string(dir_output, "i_burke_regionalimpact_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesBurke, :i_burke_regionalimpact]]), ",")
    writedlm(string(dir_output, "e_globalCO2emissions_scen", jj_scen, ".csv"), hcat(myyears, m[:co2emissions, :e_globalCO2emissions]), ",")
    writedlm(string(dir_output, "e_globalCH4emissions_scen", jj_scen, ".csv"), hcat(myyears, m[:ch4emissions, :e_globalCH4emissions]), ",")
    writedlm(string(dir_output, "e_globalLGemissions_scen", jj_scen, ".csv"), hcat(myyears, m[:LGemissions, :e_globalLGemissions]), ",")
    writedlm(string(dir_output, "e_globalN2Oemissions_scen", jj_scen, ".csv"), hcat(myyears, m[:n2oemissions, :e_globalN2Oemissions]), ",")
    writedlm(string(dir_output, "c_CO2concentration_scen", jj_scen, ".csv"), hcat(myyears, m[:co2forcing, :c_CO2concentration]), ",")
    writedlm(string(dir_output, "c_CH4concentration_scen", jj_scen, ".csv"), hcat(myyears, m[:ch4forcing, :c_CH4concentration]), ",")
    writedlm(string(dir_output, "s_sealevel_scen", jj_scen, ".csv"), hcat(myyears, m[:SeaLevelRise, :s_sealevel]), ",")
    writedlm(string(dir_output, "gdp_leveleffect_scen", jj_scen, "_ge0.0.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :gdp_leveleffect]]), ",")
    writedlm(string(dir_output, "grw_gdpgrowthrate_scen", jj_scen, "_ge0.0.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :grw_gdpgrowthrate]]), ",")
    writedlm(string(dir_output, "pop_population_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:Population, :pop_population]]), ",")
    writedlm(string(dir_output, "popgrw_populationgrowth_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:Population, :popgrw_populationgrowth]]), ",")

end



################################################################################
################### DETERMINISTIC RUN FOR EACH COMBI  ##########################
################################################################################

df_ge = DataFrame(damagePAGE09 = false, ge_rho = -999., bound_cons = -999., scen = "-999", equiw = -999., bound_equiweighting = -999.,
                    gdploss_included = -999., exogenous_disc = -999., permafr = false, seaice = false, convergence = -999.,
                        te = -999.,
                        tac = -999.,
                        tmc = -999.,
                        timp = -999.,
                        scc = -999.,
                        gdp2100 = -999., gdp2200 = -999., gdp2300 = -999.,
                        gdp2100_EU = -999., gdp2100_US = -999., gdp2100_OT = -999., gdp2100_EE = -999.,
                        gdp2100_CA = -999., gdp2100_IA = -999., gdp2100_AF = -999., gdp2100_LA = -999.,
                        gdp2200_EU = -999., gdp2200_US = -999., gdp2200_OT = -999., gdp2200_EE = -999.,
                        gdp2200_CA = -999., gdp2200_IA = -999., gdp2200_AF = -999., gdp2200_LA = -999.,
                        gdp2300_EU = -999., gdp2300_US = -999., gdp2300_OT = -999., gdp2300_EE = -999.,
                        gdp2300_CA = -999., gdp2300_IA = -999., gdp2300_AF = -999., gdp2300_LA = -999.,
                        timp_EU = -999.,
                        timp_US = -999.,
                        timp_OT = -999.,
                        timp_EE = -999.,
                        timp_CA = -999.,
                        timp_IA = -999.,
                        timp_AF = -999.,
                        timp_LA = -999.,
                        scc_EU = -999.,
                        scc_US = -999.,
                        scc_OT = -999.,
                        scc_EE = -999.,
                        scc_CA = -999.,
                        scc_IA = -999.,
                        scc_AF = -999.,
                        scc_LA = -999.,
                        scc_2020 = -999.,
                        scc_2030 = -999.,
                        scc_2040 = -999.,
                        scc_2050 = -999.,
                        scc_2075 = -999.,
                        scc_2100 = -999.,
                        scc_2150 = -999.,
                        scc_2200 = -999.,
                        scc_2250 = -999.,
                        scc_2300 = -999.
                        )


for jj_page09damages in [false, true] # RegionBayes default
    for jj_ge in [0:0.05:1;] # 0. default
        for jj_consbound in [1:1:10;] # 5 default
            for jj_scen in ["NDCs", "2.5 degC Target", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
                for jj_permafr in [true, false] # default: true
                    for jj_seaice in [true, false] # default: true
                        # print out the current state
                        print(string("Scenario: ", jj_scen, " PAGE09 damages: ", jj_page09damages, " GE: ", jj_ge, " Bound:", jj_consbound))

                        # skip combinations which are not of interest
                        if jj_scen != "RCP4.5 & SSP2" && (jj_consbound != 1. || jj_page09damages == true)
                            continue
                        elseif jj_consbound != 1. && (jj_page09damages == true || jj_permafr == false || jj_seaice == false)
                            continue
                        elseif jj_page09damages == true && (jj_permafr == false || jj_seaice == false)
                            continue
                        end

                        m = getpage(jj_scen, jj_permafr, jj_seaice, jj_page09damages)
                        update_param!(m, :civvalue_civilizationvalue, 6.1333333333333336e10*10^9) # relax the civilization value boundary
                        update_param!(m, :ge_growtheffects, jj_ge)
                        update_param!(m, :cbshare_pcconsumptionboundshare, jj_consbound)
                        run(m)

                        # write out gdp levels and growth rates which do not depend on damage calculations/weighting/discounting
                        writedlm(string(dir_output, "gdp_scen", jj_scen, "_ge", jj_ge, "_page09dam", jj_page09damages, "_permafr", jj_permafr, "_bound", jj_consbound, ".csv"),
                            hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :gdp]]), ",")
                        writedlm(string(dir_output, "percapitagdp_scen", jj_scen, "_ge", jj_ge, "_page09dam", jj_page09damages, "_permafr", jj_permafr, "_bound", jj_consbound, ".csv"),
                            hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :gdp] ./ m[:Population, :pop_population]]), ",")
                        writedlm(string(dir_output, "grw_gdpgrowthrate_scen", jj_scen, "_ge", jj_ge, "_page09dam", jj_page09damages, "_permafr", jj_permafr, "_bound", jj_consbound, ".csv"),
                            hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :grwnet_realizedgdpgrowth]]), ",")

                        # loop through remaining parameters for SCC/damage calculations
                        for jj_equiw in [0., 1.] # 1. default
                            for jj_eqwshare in [0.95, 0.99, 0.999] # 0.99 default
                                for jj_disc in [0., 3., 4.25, 7.] # 0. default
                                    for jj_gdploss in [0., 1.] # 0. default
                                        for jj_convergence in [1., 0.] # 1. default

                                            #### jump the irrelevant parameter combinations to cut runtime
                                            if jj_equiw == 1. && jj_disc != 0. # exogenous discount rates are not relevant if equity weighting applies
                                                continue
                                            # if equity weighting does not apply, all non-default settings are not of interest
                                            elseif jj_equiw == 0. && (jj_page09damages == true || jj_permafr == false || jj_seaice == false || jj_consbound != 1. || jj_scen != "RCP4.5 & SSP2" || jj_convergence == false)
                                                continue
                                            elseif jj_page09damages == true && (jj_consbound != 1 || jj_eqwshare != 0.99 || jj_disc != 0. || jj_convergence == false)
                                                continue
                                            elseif (jj_equiw == 0. || jj_gdploss == 0.) && jj_eqwshare != 0.99
                                                continue
                                            elseif jj_ge == 0. && (jj_consbound != 1 || jj_eqwshare != 0.99 || jj_gdploss != 0.)
                                                continue
                                            elseif jj_consbound != 1 && (jj_eqwshare != 0.99 || jj_disc != 0. || jj_convergence == false)
                                                continue
                                            elseif jj_scen != "RCP4.5 & SSP2" && (jj_consbound != 1 || jj_ge != 0. || jj_equiw != 1. || jj_disc != 0. || jj_convergence == false)
                                                continue
                                            end

                                            update_param!(m, :equity_proportion, jj_equiw)
                                            update_param!(m, :eqwbound_maxshareofweighteddamages, jj_eqwshare)
                                            update_param!(m, :discfix_fixediscountrate, jj_disc)
                                            update_param!(m, :lossinc_includegdplosses, jj_gdploss)
                                            update_param!(m, :use_convergence, jj_convergence)

                                            run(m)

                                            global scc_object = compute_scc_mm(m, year = 2020, pulse_size = scc_pulse_size)

                                            push!(df_ge, [jj_page09damages, jj_ge, jj_consbound, jj_scen, jj_equiw , jj_eqwshare, jj_gdploss, jj_disc,
                                                            jj_permafr, jj_seaice, jj_convergence,
                                                        m[:EquityWeighting, :te_totaleffect] / 10^6, # total effect
                                                        m[:EquityWeighting, :tac_totaladaptationcosts] / 10^6,
                                                        m[:EquityWeighting, :tpc_totalaggregatedcosts] / 10^6,
                                                        m[:EquityWeighting, :td_totaldiscountedimpacts] / 10^6,
                                                        scc_object[:scc],
                                                        sum(m[:GDP, :gdp][6, :]), # GDP in 2100
                                                        sum(m[:GDP, :gdp][8, :]), # GDP in 2200
                                                       sum(m[:GDP, :gdp][10, :]), # GDP in 2300
                                                       m[:GDP, :gdp][6, 1],
                                                       m[:GDP, :gdp][6, 2],
                                                       m[:GDP, :gdp][6, 3],
                                                       m[:GDP, :gdp][6, 4],
                                                       m[:GDP, :gdp][6, 5],
                                                       m[:GDP, :gdp][6, 6],
                                                       m[:GDP, :gdp][6, 7],
                                                       m[:GDP, :gdp][6, 8],
                                                       m[:GDP, :gdp][8, 1],
                                                       m[:GDP, :gdp][8, 2],
                                                       m[:GDP, :gdp][8, 3],
                                                       m[:GDP, :gdp][8, 4],
                                                       m[:GDP, :gdp][8, 5],
                                                       m[:GDP, :gdp][8, 6],
                                                       m[:GDP, :gdp][8, 7],
                                                       m[:GDP, :gdp][8, 8],
                                                       m[:GDP, :gdp][10, 1],
                                                       m[:GDP, :gdp][10, 2],
                                                       m[:GDP, :gdp][10, 3],
                                                       m[:GDP, :gdp][10, 4],
                                                       m[:GDP, :gdp][10, 5],
                                                       m[:GDP, :gdp][10, 6],
                                                       m[:GDP, :gdp][10, 7],
                                                       m[:GDP, :gdp][10, 8],
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 1]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 2]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 3]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 4]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 5]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 6]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 7]) / 10^6,
                                                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 8]) / 10^6,
                                                        sum(scc_object[2][:, 1]),
                                                        sum(scc_object[2][:, 2]),
                                                        sum(scc_object[2][:, 3]),
                                                        sum(scc_object[2][:, 4]),
                                                        sum(scc_object[2][:, 5]),
                                                        sum(scc_object[2][:, 6]),
                                                        sum(scc_object[2][:, 7]),
                                                        sum(scc_object[2][:, 8]),
                                                        sum(scc_object[2][1, :]),
                                                        sum(scc_object[2][2, :]),
                                                        sum(scc_object[2][3, :]),
                                                        sum(scc_object[2][4, :]),
                                                        sum(scc_object[2][5, :]),
                                                        sum(scc_object[2][6, :]),
                                                        sum(scc_object[2][7, :]),
                                                        sum(scc_object[2][8, :]),
                                                        sum(scc_object[2][9, :]),
                                                        sum(scc_object[2][10, :])
                                                        ])
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

# remove the first placeholder row
df_ge = df_ge[df_ge[:scen] .!= "-999", :]

# export the results
CSV.write(string(dir_output, "MimiPageGrowthEffectsResults.csv"), df_ge)

# export the GDP losses in absolute terms
m = getpage("RCP4.5 & SSP2")
update_param!(m, :lossinc_includegdplosses, 1.)
update_param!(m, :ge_growtheffects, 1)
update_param!(m, :cbshare_pcconsumptionboundshare, 1)
run(m)
writedlm(string(dir_output, "lgdp_gdploss_gdp_scenNDCs_ge", m[:GDP, :ge_growtheffects], "_modelspecRegionBayes_permafrYes_bound", m[:GDP, :cbshare_pcconsumptionboundshare], ".csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :lgdp_gdploss]]), ",")
writedlm(string(dir_output, "excdam_excessdamages_gdp_scenNDCs_ge", m[:GDP, :ge_growtheffects], "_modelspecRegionBayes_permafrYes_bound", m[:GDP, :cbshare_pcconsumptionboundshare], ".csv"),
                        hcat(["year"; myyears], [permutedims(myregions); m[:EquityWeighting, :excdam_excessdamages]]), ",")
writedlm(string(dir_output, "excdampv_excessdamagespresvaluep_scenNDCs_ge", m[:GDP, :ge_growtheffects], "_modelspecRegionBayes_permafrYes_bound", m[:GDP, :cbshare_pcconsumptionboundshare], ".csv"),
                                        hcat(["year"; myyears], [permutedims(myregions); m[:EquityWeighting, :excdampv_excessdamagespresvalue]]), ",")

for jj_ge in [0.45:0.05:1.0;]
    update_param!(m, :ge_growtheffects, jj_ge)
    run(m)
    writedlm(string(dir_output, "excdampv_excessdamagespresvaluep_scenNDCs_ge", m[:GDP, :ge_growtheffects], "_modelspecRegionBayes_permafrYes_bound", m[:GDP, :cbshare_pcconsumptionboundshare], ".csv"),
                                        hcat(["year"; myyears], [permutedims(myregions); m[:EquityWeighting, :excdampv_excessdamagespresvalue]]), ",")
end


# export market and total damages as %GDP
reset_masterparameters()
m = getpage("NDCs")
run(m)
writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specBurke.csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesBurke, :isat_ImpactinclSaturationandAdaptation]]), ",")
writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specPAGE09.csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamages, :isat_ImpactinclSaturationandAdaptation]]), ",")
writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specRegionBayes.csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesRegionBayes, :isat_ImpactinclSaturationandAdaptation]]), ",")
writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specRegion.csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesRegion, :isat_ImpactinclSaturationandAdaptation]]), ",")
writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specRegioinBayes.csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:EquityWeighting, :damshare_currentdamagesshare]]), ",")




################################################################################
################### STOCHASTIC MODEL RUNS    ###################################
################################################################################

df_sccMC = DataFrame(modelspec = "-999", permafr = "-999", scen = "-999", ge = "-999", gdploss = -999., civvalue = -999.,
                                    bound = -999., eqwshare = -999.,
                                  mean = -999., median = -999., min = -999., max = -999., perc25 = -999.,
                                  perc75 = -999., sd = -999., varcoeff = -999., )

# get SCC for different scenarios, specifications and with/without permafrost for level effects
for jj_spec in ["RegionBayes", "PAGE09", "Burke", "Region"]
    for jj_permafr in ["Yes", "No"]
        for jj_scen in ["NDCs", "2.5 degC Target",  "NDCs Partial", "BAU", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]

            # jump undesired combinations
            if jj_spec != "RegionBayes" && (jj_permafr == "No" || jj_scen != "NDCs")
                continue
            elseif jj_permafr == "No" && jj_scen != "NDCs"
                continue
            end

            # print the parameter combination to track progress
            print(string("Spec_", jj_spec, " Permafr_", jj_permafr, " Scen_", jj_scen))

            # define the output for the Monte Carlo files
            dir_MCoutput = string(dir_output, "montecarlo/geNO_spec", jj_spec, "_permafr", jj_permafr, "_scen", jj_scen, "/")

            # set master parameters
            reset_masterparameters()
            global permafr_master = jj_permafr
            global modelspec_master = jj_spec

            # calculate the stochastic mean SCC
            Random.seed!(masterseed)
            global scc_mcs_object = get_scc_mcs(numberofmontecarlo, 2020, dir_MCoutput, scenario = jj_scen)

            # write out the full distribution
            writedlm(string(dir_output, "SCC_MCS_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,".csv"),
                            scc_mcs_object, ",")

            # run MC for components switched off for the main specification
            if jj_permafr == "Yes" && jj_spec == "RegionBayes" && jj_scen == "NDCs"
                # repeat the procedure for components switched off
                for jj_switchoff in ["market", "nonmarket", "slr", "disc"]
                    Random.seed!(masterseed)
                    scc_mcs_object_switch = get_scc_mcs(numberofmontecarlo_sub, 2020, switch_off = jj_switchoff, scenario = jj_scen)

                    writedlm(string(dir_output, "SCC_MCS_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,
                    "_switchoff", jj_switchoff, ".csv"), scc_mcs_object_switch, ",")
                end
            end

            # push descriptive stats of the MC into the data frame
            push!(df_sccMC, [jj_spec, jj_permafr, jj_scen,
                                            "NONE", # growth effects
                                            0., # include GDP loss parameter (irrelevant for level effects)
                                            1., # civvalue multiplier (irrelevant for level effects)
                                            5., # bound
                                            0.99, # eqwshare
                                            mean(scc_mcs_object[:, 1]),
                                            median(scc_mcs_object[:, 1]),
                                            minimum(scc_mcs_object[:, 1]),
                                            maximum(scc_mcs_object[:, 1]),
                                            StatsBase.percentile(scc_mcs_object[:, 1], 25),
                                            StatsBase.percentile(scc_mcs_object[:, 1], 75),
                                            Statistics.std(scc_mcs_object[:, 1]),
                                            Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1])])

            # clean out the MCS objects
            scc_mcs_object = nothing
            scc_mcs_object_switch = nothing
        end
    end
end

# get the SCC for three different growth effects distributions and scenarios
for jj_scen in ["NDCs"] # "2.5 degC Target",  "NDCs Partial", "BAU", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    for jj_gestring in ["MILD", "MILD+TAILS", "MEDIUM", "SEVERE"]
        for jj_spec in ["RegionBayes"]
            for jj_permafr in ["Yes"]
                for jj_gdploss in [0., 1.]
                    for jj_civvalue in [1., 1000000.]
                        for jj_consbound in [5., 7.5, 10., 2.5, 1]
                            for jj_eqwshare in [0.95, 0.99, 0.999]


                        # jump undesired or infeasible combinations
                        if  jj_gdploss == 0. && jj_civvalue != 1.
                            continue
                        elseif jj_eqwshare != 0.99 && (jj_gestring != "MILD" || jj_consbound != 5. || jj_gdploss != 1. || jj_civvalue == 1.)
                            continue
                        elseif jj_consbound != 5. && (jj_gestring != "MILD" || jj_eqwshare != 0.99 || jj_gdploss != 1. || jj_civvalue == 1.)
                            continue
                        end

                        # set the ge_string parameters
                        if jj_gestring == "MILD"
                            ge_string_min = 0.
                            ge_string_mode = 0.
                            ge_string_max = 0.1
                        elseif jj_gestring == "MILD+TAILS"
                            ge_string_min = 0.
                            ge_string_mode = 0.
                            ge_string_max = 1.
                        elseif jj_gestring == "MEDIUM"
                            ge_string_min = 0.
                            ge_string_mode = 0.5
                            ge_string_max = 1.
                        elseif jj_gestring == "SEVERE"
                            ge_string_min = 0.
                            ge_string_mode = 1.
                            ge_string_max = 1.
                        end

                        # print out the parameters to track progress
                        print(string("Scen_", jj_scen, " Ge-mode_", jj_gestring))

                        # set master parameters
                        reset_masterparameters()
                        global permafr_master = jj_permafr
                        global modelspec_master = jj_spec

                        # define the output for the Monte Carlo files
                        dir_MCoutput = string(dir_output, "montecarlo/ge", jj_gestring, "_spec", jj_spec,
                                                        "_scen", jj_scen, "_gdploss", jj_gdploss,
                                                        "_civ", jj_civvalue, "_bound", jj_consbound,
                                                        "_eqwshare", jj_eqwshare, "/")

                        # calculate the stochastic mean SCC
                        Random.seed!(masterseed)
                        global scc_mcs_object = get_scc_mcs_ge(numberofmontecarlo,
                                                            2020, dir_MCoutput, scenario = jj_scen,
                                                            ge_mode = ge_string_mode, gdpincl = jj_gdploss,
                                                            ge_minimum = ge_string_min,
                                                            ge_maximum = ge_string_max,
                                                            civvalue_multiplier = jj_civvalue)

                        # write out the full distribution
                        writedlm(string(dir_output, "SCC_MCS_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,
                                                "_ge", jj_gestring, "_lossincl", jj_gdploss,
                                                "_civ", jj_civvalue,  "_bound", jj_consbound,
                                                "_eqwshare", jj_eqwshare, ".csv"),
                                                scc_mcs_object, ",")

                        # push the results into the data frame
                        push!(df_sccMC, [jj_spec, jj_permafr, jj_scen, jj_gestring, jj_gdploss, jj_civvalue,
                                        jj_consbound, jj_eqwshare,
                                                mean(scc_mcs_object[:, 1]),
                                                median(scc_mcs_object[:, 1]),
                                                minimum(scc_mcs_object[:, 1]),
                                                maximum(scc_mcs_object[:, 1]),
                                                StatsBase.percentile(scc_mcs_object[:, 1], 25),
                                                StatsBase.percentile(scc_mcs_object[:, 1], 75),
                                                Statistics.std(scc_mcs_object[:, 1]),
                                                Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1])])

                        # clean out the scc_mcs_object
                        global scc_mcs_object = nothing


                            end
                        end
                    end
                end
            end
        end
    end
end

# remove the first placeholder row
df_sccMC = df_sccMC[df_sccMC[:modelspec] .!= "-999", :]

# export the results
#CSV.write(string(dir_output, "MimiPageGrowthEffectsResultsMonteCarlo.csv"), df_sccMC)






jj_scen = "NDCs"
jj_spec = "RegionBayes"
jj_permafr = "Yes"
jj_gdploss = 1.
jj_civvalue = 1000000.
jj_consbound = 4.5
jj_eqwshare = 0.99

for jj_gestring in ["SEVERE"] # ["MILD", "MILD+TAILS", "SEVERE"] # "SEVERE"]
    # set the ge_string parameters
    if jj_gestring == "MILD"
        ge_string_min = 0.
        ge_string_mode = 0.
        ge_string_max = 0.1
    elseif jj_gestring == "MILD+TAILS"
        ge_string_min = 0.
        ge_string_mode = 0.
        ge_string_max = 1.
    elseif jj_gestring == "MEDIUM"
        ge_string_min = 0.
        ge_string_mode = 0.5
        ge_string_max = 1.
    elseif jj_gestring == "SEVERE"
        ge_string_min = 0.
        ge_string_mode = 1.
        ge_string_max = 1.
    end

    # print out the parameters to track progress
    print(string("Scen_", jj_scen, " Ge-mode_", jj_gestring))

    # set master parameters
    reset_masterparameters()
    global permafr_master = jj_permafr
    global modelspec_master = jj_spec

    # define the output for the Monte Carlo files
    dir_MCoutput = string(dir_output, "montecarlo/ge", jj_gestring, "_spec", jj_spec,
                                    "_scen", jj_scen, "_gdploss", jj_gdploss,
                                    "_civ", jj_civvalue, "_bound", jj_consbound,
                                    "_eqwshare", jj_eqwshare, "/")

    # calculate the stochastic mean SCC
    Random.seed!(masterseed)
    global scc_mcs_object = get_scc_mcs_ge(numberofmontecarlo,
                                        2020, dir_MCoutput, scenario = jj_scen,
                                        ge_mode = ge_string_mode, gdpincl = jj_gdploss,
                                        ge_minimum = ge_string_min,
                                        ge_maximum = ge_string_max,
                                        civvalue_multiplier = jj_civvalue,
                                        eqwshare = jj_eqwshare,
                                        cbshare = jj_consbound)


    # write out the full distribution
    writedlm(string(dir_output, "SCC_MCS_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,
                            "_ge", jj_gestring, "_lossincl", jj_gdploss,
                            "_civ", jj_civvalue,  "_bound", jj_consbound,
                            "_eqwshare", jj_eqwshare, ".csv"),
                            scc_mcs_object, ",")

    # push the results into the data frame
    push!(df_sccMC, [jj_spec, jj_permafr, jj_scen, jj_gestring, jj_gdploss, jj_civvalue,
                    jj_consbound, jj_eqwshare,
                            mean(scc_mcs_object[:, 1]),
                            median(scc_mcs_object[:, 1]),
                            minimum(scc_mcs_object[:, 1]),
                            maximum(scc_mcs_object[:, 1]),
                            StatsBase.percentile(scc_mcs_object[:, 1], 25),
                            StatsBase.percentile(scc_mcs_object[:, 1], 75),
                            Statistics.std(scc_mcs_object[:, 1]),
                            Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1])])

    # clean out the scc_mcs_object
    global scc_mcs_object = nothing
end

CSV.write(string(dir_output, "MimiPageGrowthEffectsResultsMonteCarlo_add.csv"), df_sccMC)


################################################################################
########################### PULSE SIZE SENSITIVITY #############################
################################################################################


df_sccpulse = DataFrame(modelspec = "-999", pulse_size = -999., actual_pulsesize = -999., scc = -999.)

for jj_spec in ["RegionBayes", "Region", "Burke", "PAGE09"]

    # get the model
    reset_masterparameters()
    global modelspec_master = jj_spec
    m = getpage("NDCs")
    run(m)

    for jj_pulsesize in [375000., 750000., 7500000.]
        print(string("pulse_size parameter is: ", jj_pulsesize, " XXX "))
        global scc = compute_scc_mm(m, year = 2020, pulse_size = jj_pulsesize)[1]

        push!(df_sccpulse, [jj_spec, jj_pulsesize, jj_pulsesize / 7.5, scc])
    end
end

showall(df_sccpulse)

CSV.write(string(dir_output, "MimiPagePulseSizeSensitivity_add.csv"), df_sccpulse)
