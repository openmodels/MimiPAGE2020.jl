################################################################################
###################### FIT MODEL AND EXTRACT STATIC VARIABLES ##################
################################################################################


using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random

# define a function to reset the master parameters
function reset_masterparameters()
    global modelspec_master = "RegionBayes" # "RegionBayes" (default), "Region", "Burke" or "PAGE09"
    global ge_master = 0.0                  # 0.0 (default), any other Float between 0 and 1
    global equiw_master = "Yes"             # "Yes" (default), "No", "DFC"
    global gdploss_master = "Excl"          # "Excl" (default), "Incl"
    global permafr_master = "Yes"           # "Yes" (default), "No"
    global gedisc_master = "No"             # "No" (default), "Yes", "Only" (feeds only discontinuity impacts into growth rate)

    "All master parameters reset to defaults"
end


Base.include(Main, "getpagefunction.jl")
Base.include(Main, "utils/mctools.jl")
Base.include(Main, "mcs.jl")

# define the model regions in the order that Mimi returns stuff
myregions = ["EU", "USA", "Other OECD","Former USSR","China","Southeast Asia","Africa","Latin America"]
myyears = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]

# define the output directory
dir_output = "C:/Users/nasha/Documents/GitHub/damage-regressions/data/mimi-page-output/"

# define number of Monte Carlo runs
global numberofmontecarlo = 10^4

# run the model with default settings
reset_masterparameters()
m = getpage()
run(m)




### export some parameters which are (fairly) constant across master parameter settings

# baseline GDP and percap consumption
writedlm(string(dir_output, "gdp_0.csv"), hcat(myregions, m[:GDP, :gdp_0]), ",")
writedlm(string(dir_output, "cons_percap_consumption_0.csv"), hcat(myregions, m[:GDP, :cons_percap_consumption_0]), ",")
writedlm(string(dir_output, "rtl_abs_0_realizedabstemperature.csv"), hcat(myregions, m[:MarketDamagesBurke, :rtl_abs_0_realizedabstemperature]), ",")

# export variables which depend only on the scenario
writedlm(string(dir_output, "rtl_realizedtemperature_scenNDCs.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:ClimateTemperature, :rtl_realizedtemperature]]), ",")
writedlm(string(dir_output, "rtl_realizedtemperature_scenNDCs.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:ClimateTemperature, :rtl_realizedtemperature]]), ",")
writedlm(string(dir_output, "rt_g_globaltemperature_scenNDCs.csv"), hcat(myyears, m[:ClimateTemperature, :rt_g_globaltemperature]), ",")
writedlm(string(dir_output, "i_burke_regionalimpact_scenNDCs.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesBurke, :i_burke_regionalimpact]]), ",")
writedlm(string(dir_output, "e_globalCO2emissions_scenNDCs.csv"), hcat(myyears, m[:co2emissions, :e_globalCO2emissions]), ",")
writedlm(string(dir_output, "e_globalCH4emissions_scenNDCs.csv"), hcat(myyears, m[:ch4emissions, :e_globalCH4emissions]), ",")
writedlm(string(dir_output, "e_globalLGemissions_scenNDCs.csv"), hcat(myyears, m[:LGemissions, :e_globalLGemissions]), ",")
writedlm(string(dir_output, "e_globalN2Oemissions_scenNDCs.csv"), hcat(myyears, m[:n2oemissions, :e_globalN2Oemissions]), ",")
writedlm(string(dir_output, "c_CO2concentration_scenNDCs.csv"), hcat(myyears, m[:co2forcing, :c_CO2concentration]), ",")
writedlm(string(dir_output, "c_CH4concentration_scenNDCs.csv"), hcat(myyears, m[:ch4forcing, :c_CH4concentration]), ",")
writedlm(string(dir_output, "s_sealevel_scenNDCs.csv"), hcat(myyears, m[:SeaLevelRise, :s_sealevel]), ",")
writedlm(string(dir_output, "gdp_scenNDCs_ge0.0.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :gdp]]), ",")
writedlm(string(dir_output, "grw_gdpgrowthrate_scenNDCs_ge0.0.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :grw_gdpgrowthrate]]), ",")
writedlm(string(dir_output, "pop_population.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:Population, :pop_population]]), ",")
writedlm(string(dir_output, "popgrw_populationgrowth.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:Population, :popgrw_populationgrowth]]), ",")


########################################################
################### DAMAGES & SCC ######################
########################################################

df_damages = DataFrame(modelspec = "-999", scen = "-999", equiw = "-999", permafr = "-999",
                        te = -999.,
                        tac = -999.,
                        tmc = -999.,
                        timp = -999.,
                        scc = -999.,
                        scc_mcs_mean = -999.,
                        scc_mcs_median = -999.,
                        timp_EU = -999.,
                        timp_US = -999.,
                        timp_OT = -999.,
                        timp_EE = -999.,
                        timp_CA = -999.,
                        timp_IA = -999.,
                        timp_AF = -999.,
                        timp_LA = -999.,
                        scc_marketshare = -999.,
                        scc_nonmarketshare = -999.,
                        scc_SLRshare = -999.,
                        scc_discshare = -999.,
                        scc_EU = -999.,
                        scc_US = -999.,
                        scc_OT = -999.,
                        scc_EE = -999.,
                        scc_CA = -999.,
                        scc_IA = -999.,
                        scc_AF = -999.,
                        scc_LA = -999.)


global jj_equiw = "Yes"

for jj_spec in ["RegionBayes", "PAGE09", "Burke", "Region"]
    for jj_permafr in ["Yes", "No"]

        # set master parameters
        reset_masterparameters()
        global scen_master = "NDCs"
        global permafr_master = jj_permafr
        global modelspec_master = jj_spec

        # print out parameters to follow the loop
        print(jj_spec)
        print(jj_permafr)

        # set up the model
        m = getpage()
        run(m)
        global scc = compute_scc(m, year = 2020)

        # repeat for market damages switched off
        update_param!(m, :switchoff_marketdamages, 1.)
        run(m)
        global scc_marketshare = scc - compute_scc(m, year = 2020)

        update_param!(m, :switchoff_marketdamages, 0.)
        update_param!(m, :switchoff_nonmarketdamages, 1.)
        run(m)
        global scc_nonmarketshare = scc - compute_scc(m, year = 2020)

        update_param!(m, :switchoff_nonmarketdamages, 0.)
        update_param!(m, :switchoff_SLRdamages, 1.)
        run(m)
        global scc_SLRshare = scc - compute_scc(m, year = 2020)

        update_param!(m, :switchoff_SLRdamages, 0.)
        update_param!(m, :switchoff_discontinuity, 1.)
        run(m)
        global scc_discshare = scc - compute_scc(m, year = 2020)

        # set back to default
        update_param!(m, :switchoff_discontinuity, 0.)
        run(m)

        # calculate the disaggregated scc
        global scc = compute_scc_mm(m, year = 2020)

        # calculate the stochastic mean SCC
        if jj_permafr == "Yes" || (jj_permafr == "No" && jj_spec == "RegionBayes")
            Random.seed!(1)
            global scc_mcs_object = get_scc_mcs(numberofmontecarlo, 2020)

            # write out the SCC distribution
            writedlm(string(dir_output, "SCC_MCS_spec", jj_spec, "_permafr", jj_permafr, ".csv"), scc_mcs_object, ",")
        end

        if jj_permafr == "Yes" && jj_spec == "RegionBayes"
            # repeat the procedure for components switched off
            for jj_switchoff in ["market", "nonmarket", "slr", "disc"]
                Random.seed!(1)
                global scc_mcs_object = get_scc_mcs(numberofmontecarlo, 2020, switch_off = jj_switchoff)

                writedlm(string(dir_output, "SCC_MCS_spec", jj_spec, "_permafr", jj_permafr,
                "_switchoff", jj_switchoff, ".csv"), scc_mcs_object, ",")
            end
        end

        # write out the disaggregated SCC
        if jj_permafr == "Yes"
            writedlm(string(dir_output, "scc_disaggregated_modelspec", jj_spec, "_permafr", jj_permafr, ".csv"),
                        hcat(["year"; myyears], [permutedims(myregions); scc[2]]), ",")
        end

        # output the parameters of interest
        push!(df_damages, [jj_spec, "NDCs", jj_equiw, jj_permafr,
                        m[:EquityWeighting, :te_totaleffect] / 10^6, # total effect
                        m[:EquityWeighting, :tac_totaladaptationcosts] / 10^6,
                        m[:EquityWeighting, :tpc_totalaggregatedcosts] / 10^6,
                        m[:EquityWeighting, :td_totaldiscountedimpacts] / 10^6,
                        scc[:scc],
                        ifelse(jj_permafr == "Yes" || (jj_permafr == "No" && jj_spec == "RegionBayes"), mean(scc_mcs_object), -999.),
                        ifelse(jj_permafr == "Yes" || (jj_permafr == "No" && jj_spec == "RegionBayes"), median(scc_mcs_object), -999.),
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 1]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 2]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 3]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 4]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 5]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 6]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 7]) / 10^6,
                        sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, 8]) / 10^6,
                        scc_marketshare,
                        scc_nonmarketshare,
                        scc_SLRshare,
                        scc_discshare,
                        sum(scc[2][:, 1]),
                        sum(scc[2][:, 2]),
                        sum(scc[2][:, 3]),
                        sum(scc[2][:, 4]),
                        sum(scc[2][:, 5]),
                        sum(scc[2][:, 6]),
                        sum(scc[2][:, 7]),
                        sum(scc[2][:, 8])
                        ])

        # export the market damages for the differenct specifications
        if jj_permafr == "Yes" && jj_spec == "RegionBayes"
            writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specRegionBayes.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesRegionBayes, :isat_ImpactinclSaturationandAdaptation]]), ",")
            writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specRegion.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesRegion, :isat_ImpactinclSaturationandAdaptation]]), ",")
            writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specPAGE09.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamages, :isat_ImpactinclSaturationandAdaptation]]), ",")
            writedlm(string(dir_output, "isat_market_scenNDCs_permafrYes_specBurke.csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesBurke, :isat_ImpactinclSaturationandAdaptation]]), ",")
        end

        if jj_permafr == "Yes"
            writedlm(string(dir_output, "WeightedImpacts_permafrYes_spec", jj_spec, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]]), ",")
        end
    end
end

# remove the first placeholder row
df_out = df_damages[df_damages[:modelspec] .!= "-999", :]

# export the SCC and its decomposition for all pulse-year pairs into a csv file
CSV.write(string(dir_output, "MimiPageDamagesResults.csv"), df_out)


# run the sensitivity analysis from sensitivityanalysis.jl
include("sensitivityanalysis.jl")

########################################################
################### GROWTH EFFECTS #####################
########################################################

# extract GDP for all relevant parameter combinations
for jj_scen in ["NDCs"]
    for jj_ge in [0:0.05:1;]
        for jj_permafr in ["Yes", "No"]
            for jj_gedisc in ["No", "Yes"]
                # jump certain parameter combinations
                if jj_permafr == "No" && jj_ge > 0.1
                    continue
                elseif jj_gedisc == "Yes" && jj_ge > 0.2
                    continue
                end

                # set the global parameters accordingly
                reset_masterparameters()
                global scen_master = jj_scen
                global ge_master = jj_ge
                global permafr_master = jj_permafr
                global gedisc_master = jj_gedisc

                # run the model
                m = getpage()
                run(m)

                # export GDP
                writedlm(string(dir_output, "gdp_scen", jj_scen, "_ge", jj_ge, "_permafr", jj_permafr,
                                "_gedisc", jj_gedisc, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :gdp]]), ",")
            end
        end
    end
end


# extract isat for all relevant parameter combinations
for jj_scen in ["NDCs"]
    for jj_spec in ["RegionBayes", "PAGE09", "Burke"]
        for jj_permafr in ["Yes"]

            # set master parameters
            reset_masterparameters()
            global scen_master = jj_scen
            global modelspec_master = jj_spec
            global permafr_master = jj_permafr

            # export the variable
            if jj_spec == "RegionBayes"
                writedlm(string(dir_output, "isat_ImpactinclSaturationandAdaptation_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,
                            ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesRegionBayes, :isat_ImpactinclSaturationandAdaptation]]), ",")
            elseif jj_spec == "PAGE09"
                writedlm(string(dir_output, "isat_ImpactinclSaturationandAdaptation_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,
                            ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamages, :isat_ImpactinclSaturationandAdaptation]]), ",")
            elseif jj_spec == "Burke"
                writedlm(string(dir_output, "isat_ImpactinclSaturationandAdaptation_scen", jj_scen, "_spec", jj_spec, "_permafr", jj_permafr,
                            ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesBurke, :isat_ImpactinclSaturationandAdaptation]]), ",")

            else
                error("The damage component used for extracting the isat variable is not specificed in the loop. Please adjust the loop")
            end
        end
    end
end



################################################################################
############### LOOP THROUGH PARAMETERS AND EXTRACT RESULTS ####################
################################################################################

### Set up the data frame in which results will be stored

# create a data frame where results will be stored
df_out = DataFrame(modelspec = "-999", scen = "-999", ge = -999., equiw = "-999", gdploss = "-999", permafr = "-999", gedisc = "-999",
                        te = -999., td = -999., tpc = -999., tac = -999.,
                        absimpacts = -999.,
                        scc = -999.,
                        scc_womarket = -999., scc_wononmarket = -999., scc_woSLR = -999., scc_wodisc = -999., scc_interaction = -999.,
                        scc_EU = -999.,
                        scc_US = -999.,
                        scc_OT = -999.,
                        scc_EE = -999.,
                        scc_CA = -999.,
                        scc_IA = -999.,
                        scc_AF = -999.,
                        scc_LA = -999.,
                        yearpulse = -999, pulse_size = -999.,
                        rtg_pulse2100 = -999., rtg_pulse2200 = -999., rtg_pulse2300 = -999.,
                        gdp2100_pulse = -999., gdp2200_pulse = -999., gdp2300_pulse = -999.,
                        gdp2100 = -999., gdp2200 = -999., gdp2300 = -999.,
                        gdp2100_EU = -999., gdp2100_US = -999., gdp2100_OT = -999., gdp2100_EE = -999.,
                        gdp2100_CA = -999., gdp2100_IA = -999., gdp2100_AF = -999., gdp2100_LA = -999.,
                        gdp2200_EU = -999., gdp2200_US = -999., gdp2200_OT = -999., gdp2200_EE = -999.,
                        gdp2200_CA = -999., gdp2200_IA = -999., gdp2200_AF = -999., gdp2200_LA = -999.,
                        gdp2300_EU = -999., gdp2300_US = -999., gdp2300_OT = -999., gdp2300_EE = -999.,
                        gdp2300_CA = -999., gdp2300_IA = -999., gdp2300_AF = -999., gdp2300_LA = -999.,
                        absi_EU = -999.,
                        absi_US = -999.,
                        absi_OT = -999.,
                        absi_EE = -999.,
                        absi_CA = -999.,
                        absi_IA = -999.,
                        absi_AF = -999.,
                        absi_LA = -999.)


### Set Loop Parameters and Loop Through Them, Saving Results into df_out

# set parameters which are currently held constant but might be included in the loop
reset_masterparameters()
global jj_scen = "NDCs"
global jj_year = 2020

# loop through different pulse years and magnitudes
for jj_spec in ["RegionBayes", "Burke", "Region", "PAGE09"]
    for jj_ge in [0:0.05:1;]
        for jj_equiw in ["Yes", "No", "DFC"]
            for jj_gdploss in ["Excl", "Incl"]
                for jj_permafr in ["Yes", "No"]
                    for jj_gedisc in ["No", "Yes", "Only"]
                        for jj_pulse in [1000., 100000., 10000000.]
                            for jj_year in [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250]
                                # jump to next iteration immediately if the parameter combination is somehow toxic or not of interest
                                if jj_permafr == "No" && (jj_ge > 0.05 || jj_spec != "RegionBayes" || jj_gedisc != "No" || jj_gdploss != "Excl" || jj_equiw == "No")
                                    continue
                                elseif jj_pulse != 100000. && (jj_spec != "RegionBayes" || jj_gedisc != "No" || jj_ge != 0. || jj_permafr != "Yes" || jj_equiw == "No" || jj_gdploss != "Excl" || jj_year != 2020)
                                    continue
                                elseif jj_year != 2020 && (jj_spec != "RegionBayes" || jj_gedisc != "No" || jj_ge != 0. || jj_permafr != "Yes" || jj_equiw == "No" || jj_gdploss != "Excl")
                                    continue
                                end


                                ### PART 1: compute the SCC and its disaggregation over time and regions

                                # set the master parameters accordingly
                                global modelspec_master = jj_spec
                                global scen_master = jj_scen
                                global ge_master = jj_ge
                                global equiw_master = jj_equiw
                                global gdploss_master = jj_gdploss
                                global permafr_master = jj_permafr
                                global gedisc_master = jj_gedisc

                                # train a model without a pulse
                                m_nopulse = getpage()
                                run(m_nopulse)

                                # compute SCC
                                scc = compute_scc_mm(m_nopulse, year = jj_year, pulse_size = jj_pulse)

                                # write out the disaggregated version for selected parameter ranges
                                if jj_ge in [0, 0.05] && jj_equiw == "Yes" && jj_gdploss == "Excl" && jj_spec in ["RegionBayes"] && jj_permafr == "Yes"
                                        writedlm(string(dir_output, "scc_disaggregated_modelspec", jj_spec, "_scen", jj_scen, "_ge", jj_ge,
                                                        "_equiw", jj_equiw, "_gdploss", jj_gdploss, "_permafr", jj_permafr, "_gedisc", jj_gedisc,
                                                        "_pulse", jj_pulse, "_yearpulse", jj_year, ".csv"),
                                                    hcat(["year"; myyears], [permutedims(myregions); scc[2]]), ",")
                                end

                                # compute the SCCs with different damage components switched off
                                update_param!(m, :switchoff_marketdamages, 1.)
                                run(m)
                                scc_womarket = scc[1] - compute_scc_mm(m, year = jj_year)[1]

                                update_param!(m, :switchoff_marketdamages, 0.)
                                update_param!(m, :switchoff_nonmarketdamages, 1.)
                                run(m)
                                scc_wononmarket = scc[1] - compute_scc_mm(m, year = jj_year)[1]

                                update_param!(m, :switchoff_nonmarketdamages, 0.)
                                update_param!(m, :switchoff_SLRdamages, 1.)
                                run(m)
                                scc_woSLR = scc[1] - compute_scc_mm(m, year = jj_year)[1]

                                update_param!(m, :switchoff_SLRdamages, 0.)
                                update_param!(m, :switchoff_disc, 1.)
                                run(m)
                                scc_wodisc = scc[1] - compute_scc_mm(m, year = jj_year)[1]

                                # write the SCC and the contributions from the components into df_out
                                push!(df_out, [jj_spec, jj_scen, jj_ge, jj_equiw, jj_gdploss, jj_permafr, jj_gedisc,
                                                m_nopulse[:EquityWeighting, :te_totaleffect], # total effect
                                                m_nopulse[:EquityWeighting, :td_totaldiscountedimpacts],
                                                m_nopulse[:EquityWeighting, :tpc_totalaggregatedcosts],
                                                m_nopulse[:EquityWeighting, :tac_totaladaptationcosts],
                                                sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,:]),
                                                scc[1],
                                                scc_womarket,
                                                scc_wononmarket,
                                                scc_woSLR,
                                                scc_wodisc,
                                                scc[1] - scc_womarket - scc_wononmarket - scc_woSLR - scc_wodisc,
                                                sum(scc[2][:, 1]),
                                                sum(scc[2][:, 2]),
                                                sum(scc[2][:, 3]),
                                                sum(scc[2][:, 4]),
                                                sum(scc[2][:, 5]),
                                                sum(scc[2][:, 6]),
                                                sum(scc[2][:, 7]),
                                                sum(scc[2][:, 8]),
                                                jj_year,
                                                scc[3][:co2emissions, :e_globalCO2emissions][1],
                                                scc[3][:ClimateTemperature, :rt_g_globaltemperature][6],
                                                scc[3][:ClimateTemperature, :rt_g_globaltemperature][8],
                                                scc[3][:ClimateTemperature, :rt_g_globaltemperature][10],
                                                scc[3][:GDP, :gdp][6],
                                                scc[3][:GDP, :gdp][8],
                                                scc[3][:GDP, :gdp][10],
                                                sum(m_nopulse[:GDP, :gdp][6, :]), # GDP in 2100
                                                sum(m_nopulse[:GDP, :gdp][8, :]), # GDP in 2200
                                               sum(m_nopulse[:GDP, :gdp][10, :]), # GDP in 2300
                                               m_nopulse[:GDP, :gdp][6, 1],
                                               m_nopulse[:GDP, :gdp][6, 2],
                                               m_nopulse[:GDP, :gdp][6, 3],
                                               m_nopulse[:GDP, :gdp][6, 4],
                                               m_nopulse[:GDP, :gdp][6, 5],
                                               m_nopulse[:GDP, :gdp][6, 6],
                                               m_nopulse[:GDP, :gdp][6, 7],
                                               m_nopulse[:GDP, :gdp][6, 8],
                                               m_nopulse[:GDP, :gdp][8, 1],
                                               m_nopulse[:GDP, :gdp][8, 2],
                                               m_nopulse[:GDP, :gdp][8, 3],
                                               m_nopulse[:GDP, :gdp][8, 4],
                                               m_nopulse[:GDP, :gdp][8, 5],
                                               m_nopulse[:GDP, :gdp][8, 6],
                                               m_nopulse[:GDP, :gdp][8, 7],
                                               m_nopulse[:GDP, :gdp][8, 8],
                                               m_nopulse[:GDP, :gdp][10, 1],
                                               m_nopulse[:GDP, :gdp][10, 2],
                                               m_nopulse[:GDP, :gdp][10, 3],
                                               m_nopulse[:GDP, :gdp][10, 4],
                                               m_nopulse[:GDP, :gdp][10, 5],
                                               m_nopulse[:GDP, :gdp][10, 6],
                                               m_nopulse[:GDP, :gdp][10, 7],
                                               m_nopulse[:GDP, :gdp][10, 8],
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,1]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,2]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,3]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,4]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,5]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,6]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,7]),
                                               sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,8])
                                               ])


                                # clean out the parameters
                                global scc = -999.
                            end
                        end
                    end
                end
            end
        end
    end
end

# remove the first placeholder row
df_out = df_out[df_out[:ge] .!= -999., :]

# export the SCC and its decomposition for all pulse-year pairs into a csv file
CSV.write(string(dir_output, "MimiPageResults.csv"), df_out)





# check whether the master parameters were executed correctly
if ge_master != m[:GDP, :ge_growtheffects]
    error("ge_master and ge_growtheffects in GDP are not aligned. Please correct this discrepancy in the source code")
end
if (equiw_master == "Yes" && m[:EquityWeighting, :equity_proportion] != 1.0) || (equiw_master == "No" && m[:EquityWeighting, :equity_proportion] != 0.0)
    error("equiw_master and equity proportion in EquityWeighting are not aligned. Please correct this discrepancy in the source code")
end
if (equiw_master == "DFC" && m[:EquityWeighting, :equity_proportion] != 0.0)
    error("equiw_master and equity proportion in EquityWeighting are not aligned. Please correct this discrepancy in the source code")
end
if (equiw_master == "DFC" && m[:EquityWeighting, :dfc_feedback] != 1.0) || (equiw_master != "DFC" && m[:EquityWeighting, :dfc_feedback] != 0.0)
    error("equiw_master and dfc_feedback in EquityWeighting are not aligned. Please correct this discrepancy in the source code")
end
if (gdploss_master == "Excl" && m[:EquityWeighting, :gdploss_included] != 0.) || (gdploss_master == "Incl" && m[:EquityWeighting, :gdploss_included] != 1.)
    error("gdploss_master and gdploss_included in EquityWeighting are not aligned. Please correct this discrepancy in the source code")
end
if (permafr_master == "Yes" && m[:CH4Cycle, :permtce0_permafrostemissions0] == 0) || (permafr_master == "No" && m[:CH4Cycle, :permtce0_permafrostemissions0] != 0)
    error("permafr_master and permtce0_permafrostemissions in CH4Cycle are not aligned. Please correct this discrepancy in the source code")
end
if (gedisc_master == "Yes" && m[:GDP, :gedisc_included] != 1.0) || (gedisc_master == "No" && m[:GDP, :gedisc_included] != 0.0)
    error("gedisc_master and gedisc_included in GDP are not aligned. Please correct this discrepancy in the source code")
end
