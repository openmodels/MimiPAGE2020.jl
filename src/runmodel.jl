################################################################################
###################### FIT MODEL AND EXTRACT STATIC VARIABLES ##################
################################################################################


using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV

include("getpagefunction.jl")
include("utils/mctools.jl")

# define the model regions in the order that Mimi returns stuff
myregions = ["EU", "US", "OT","EE","CA","IA","AF","LA"]
myyears = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]

# define the output directory
dir_output = "C:/Users/nasha/Documents/GitHub/damage-regressions/data/mimi-page-output/"

# run the model with default settings
reset_masterparameters()
m = getpage()
run(m)

# check whether the master parameters were executed correctly
if ge_master != m[:GDP, :ge_growtheffects]
    error("ge_master and ep_CO2emissionpulse in CO2emissions are not aligned. Please correct this discrepancy in the source code")
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
if sccpulse_master != m[:co2emissions, :ep_CO2emissionpulse]
    error("sccpulse_master and ep_CO2emissionpulse in CO2emissions are not aligned. Please correct this discrepancy in the source code")
end
if yearpulse_master != m[:co2emissions, :y_pulse]
    error("yearpulse_master and y_pulse in CO2emissions are not aligned. Please correct this discrepancy in the source code")
end
if (gedisc_master == "Yes" && m[:GDP, :gedisc_included] != 1.0) || (gedisc_master == "No" && m[:GDP, :gedisc_included] != 0.0)
    error("gedisc_master and gedisc_included in GDP are not aligned. Please correct this discrepancy in the source code")
end



### export some parameters which are (fairly) constant across master parameter settings

# baseline GDP
writedlm(string(dir_output, "gdp_0.csv"), hcat(myregions, m[:GDP, :gdp_0]), ",")

# get scenario-dependent variables
for jj_scen in ["NDCs"]
    # set master parameters
    reset_masterparameters()
    global scen_master = jj_scen

    # run the model
    m = getpage()
    run(m)

    # export variables which depend only on the scenario
    writedlm(string(dir_output, "rtl_realizedtemperature_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:ClimateTemperature, :rtl_realizedtemperature]]), ",")
    writedlm(string(dir_output, "rt_g_globaltemperature_scen", jj_scen, ".csv"), hcat(myyears, m[:ClimateTemperature, :rt_g_globaltemperature]), ",")
    writedlm(string(dir_output, "i_burke_regionalimpact_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:MarketDamagesBurke, :i_burke_regionalimpact]]), ",")
    writedlm(string(dir_output, "pop_population_scen", jj_scen, ".csv"), hcat(["year"; myyears], [permutedims(myregions); m[:Population, :pop_population]]), ",")
end

# extract GDP for all relevant parameter combinations
for jj_scen in ["NDCs"]
    for jj_ge in [0., 0.05, 0.1, 0.15, 0.2]
        for jj_permafr in ["Yes", "No"]
            for jj_gedisc in ["No", "Yes"]

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
    for jj_spec in ["RegionBayes", "PAGE09"]
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
            else
                error("The damage component used for extraction the isat variable is not specificed in the loop. Please adjust the loop")
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
                        te = -999., absimpacts = -999.,
                        scc = -999.,
                        yearpulse = -999, exppulse = -999,
                        gdp2100 = -999., gdp2200 = -999., gdp2300 = -999.,
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
global jj_exp = 0
global jj_year = 2020

# loop through different pulse years and magnitudes
for jj_spec in ["RegionBayes", "Burke", "Region", "PAGE09"]
    for jj_ge in [0:0.05:1;]
        for jj_equiw in ["Yes", "No", "DFC"]
            for jj_gdploss in ["Excl", "Incl"]
                for jj_permafr in ["Yes", "No"]
                    for jj_gedisc in ["No", "Yes"]
                        # jump to next iteration immediately if the parameter combination is somehow toxic
                        if jj_gedisc == "Yes" && jj_ge >= 0.7
                            continue
                        elseif jj_spec in ["PAGE09", "Region"] && jj_ge > 0.6
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

                        global sccpulse_master = 0.
                        global yearpulse_master = jj_year

                        # train a model without a pulse
                        m_nopulse = getpage()
                        run(m_nopulse)

                        # create a model with pulse
                        global sccpulse_master = 10^(jj_exp)
                        m_withpulse = getpage()
                        run(m_withpulse)

                        # compute stuff only if the resulting emissions for the models check out
                        if m_withpulse[:co2emissions, :e_globalCO2emissions][1] == m_nopulse[:co2emissions, :e_globalCO2emissions][1] .+ m_withpulse[:co2emissions, :ep_CO2emissionpulse] && m_withpulse[:co2emissions, :e_globalCO2emissions][2] == m_nopulse[:co2emissions, :e_globalCO2emissions][2]
                            # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
                            global scc = (m_withpulse[:EquityWeighting, :te_totaleffect] - m_nopulse[:EquityWeighting, :te_totaleffect]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
                            # Note: disaggregation does not work as abatement costs are driven by baseline emissions and growth rate, not by levels at time t

                            # disaggregate SCC by region and time
                            scc_disaggregated = (m_withpulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                                    m_nopulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]

                            # write out the disaggregated version for selected parameter ranges
                            if jj_ge in [0, 0.05] && jj_equiw == "Yes" && jj_gdploss == "Excl" && jj_spec in ["RegionBayes"] && jj_permafr == "Yes"
                                writedlm(string(dir_output, "scc_disaggregated_modelspec", jj_spec, "_scen", jj_scen, "_ge", jj_ge,
                                                "_equiw", jj_equiw, "_gdploss", jj_gdploss, "_permafr", jj_permafr, "_gedisc", jj_gedisc,
                                                "_exppulse", jj_exp, "_yearpulse", jj_year, ".csv"),
                                            hcat(["year"; myyears], [permutedims(myregions); scc_disaggregated]), ",")
                            end
                        else
                            error("CO2 pulse was not executed correctly. Emissions differ in the second time period or do not have the pre-specified difference in the first.")
                        end


                        # write the SCC and the contributions from the components into df_out
                        push!(df_out, [jj_spec, jj_scen, jj_ge, jj_equiw, jj_gdploss, jj_permafr, jj_gedisc,
                                        m_nopulse[:EquityWeighting, :te_totaleffect], # total effect
                                        sum(((m_nopulse[:EquityWeighting, :cons_percap_aftercosts] .- m_nopulse[:EquityWeighting, :rcons_percap_dis]) .* m_nopulse[:Population, :pop_population])[:,:]),
                                        scc, # XX change this once scc computations are merged in
                                        jj_year,
                                        jj_exp,
                                        sum(m_nopulse[:GDP, :gdp][6, :]), # GDP in 2100
                                        sum(m_nopulse[:GDP, :gdp][8, :]), # GDP in 2200
                                       sum(m_nopulse[:GDP, :gdp][10, :]), # GDP in 2300
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

# remove the first placeholder row
df_out = df_out[df_out[:ge] .!= -999., :]

# export the SCC and its decomposition for all pulse-year pairs into a csv file
CSV.write(string(dir_output, "MimiPageResults.csv"), df_out)



################################################################################
###################### MORE DETAILED SCC DISAGGREGATION ########################
################################################################################

# create a data frame where SCCs will be stored
df_outscc = DataFrame(modelspec = "-999", scen = "-999", ge = -999., equiw = "-999", gdploss = "-999", permafr = "-999", gedisc = "-999",
                    exppulse = -999, yearpulse = -999,
                    scc = -999., market_contr = -999.,
                    nonmarket_contr = -999., SLR_contr = -999., disc_contr = -999., interaction_contr = -999.,
                    scc_EU = -999.,
                    scc_US = -999.,
                    scc_OT = -999.,
                    scc_EE = -999.,
                    scc_CA = -999.,
                    scc_IA = -999.,
                    scc_AF = -999.,
                    scc_LA = -999.)

# set the master parameters which are currently not looped through
reset_masterparameters()
global jj_scen = "NDCs"
global jj_gdploss = "Excl"
global jj_permafr = "Yes"
global jj_gedisc = "No"

# loop through different pulse years and magnitudes
for jj_spec in ["RegionBayes", "PAGE09"]
    for jj_ge in [0., 0.05]
        for jj_equiw in ["Yes", "DFC"]
            for jj_year in [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250]
                for jj_exp in [-6.:1:6.;]

                    # jump to next iteration for too detailed combination of by-year and by-pulse disaggregation to cut runtime
                    if jj_exp != 0 && jj_year != 2020
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

                    # clear the parameters
                    global getscc_womarket = false
                    global getscc_wononmarket = false
                    global getscc_woSLR = false
                    global getscc_wodisc = false

                    # set the pulse parameter zero, i.e. no pulse and compute the model
                    global sccpulse_master = 0
                    global yearpulse_master = jj_year
                    m_nopulse = getpage()
                    run(m_nopulse)

                    # create a model with pulse of +1MT CO2 at t = 1
                    global sccpulse_master = 10^(jj_exp)
                    m_withpulse = getpage()
                    run(m_withpulse)

                    # get the time step
                    ind = findall(x -> x == jj_year, m_nopulse[:co2emissions, :y_year])

                    # compute stuff only if the resulting emissions for the models check out
                    if m_withpulse[:co2emissions, :e_globalCO2emissions][ind] == m_nopulse[:co2emissions, :e_globalCO2emissions][ind] .+ m_withpulse[:co2emissions, :ep_CO2emissionpulse] && m_withpulse[:co2emissions, :e_globalCO2emissions][ind .+ 1] == m_nopulse[:co2emissions, :e_globalCO2emissions][ind .+ 1]
                        # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
                        global scc = (m_withpulse[:EquityWeighting, :te_totaleffect] - m_nopulse[:EquityWeighting, :te_totaleffect]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
                        # Note: disaggregation does not work as abatement costs are driven by baseline emissions and growth rate, not by levels at time t
                        #scc_imp = (m_withpulse[:EquityWeighting, :td_totaldiscountedimpacts] - m_nopulse[:EquityWeighting, :td_totaldiscountedimpacts]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
                        #scc_adt = (m_withpulse[:EquityWeighting, :tac_totaladaptationcosts] - m_nopulse[:EquityWeighting, :tac_totaladaptationcosts]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
                        #scc_abm = (m_withpulse[:EquityWeighting, :tpc_totalaggregatedcosts] - m_nopulse[:EquityWeighting, :tpc_totalaggregatedcosts]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]

                        # disaggregate SCC by region and time
                        scc_disaggregated = (m_withpulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                                m_nopulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]


                        #### PART 2: calculate component contributions to overall SCC by switching them off

                        # create a model without the market damages and run with and without pulse
                        global getscc_womarket = true
                        global sccpulse_master = 0
                        m_nopulse_womarket = getpage()
                        run(m_nopulse_womarket)
                        global sccpulse_master = 10^(jj_exp)
                        m_withpulse_womarket = getpage()
                        run(m_withpulse_womarket)
                        global getscc_womarket = false

                        # model without SLR damages
                        global getscc_woSLR = true
                        global sccpulse_master = 0
                        m_nopulse_woSLR = getpage()
                        run(m_nopulse_woSLR)
                        global sccpulse_master = 10^(jj_exp)
                        m_withpulse_woSLR = getpage()
                        run(m_withpulse_woSLR)
                        global getscc_woSLR = false

                        # create a model without nonmarket damages
                        global getscc_wononmarket = true
                        global sccpulse_master = 0
                        m_nopulse_wononmarket = getpage()
                        run(m_nopulse_wononmarket)
                        global sccpulse_master = 10^(jj_exp)
                        m_withpulse_wononmarket = getpage()
                        run(m_withpulse_wononmarket)
                        global getscc_wononmarket = false

                        # without discontinuity
                        global getscc_wodisc = true
                        global sccpulse_master = 0
                        m_nopulse_wodisc = getpage()
                        run(m_nopulse_wodisc)
                        global sccpulse_master = 10^(jj_exp)
                        m_withpulse_wodisc = getpage()
                        run(m_withpulse_wodisc)
                        global getscc_wodisc = false


                        # repeat the SCC computation for models without market damages
                        global scc_womarket = scc - (m_withpulse_womarket[:EquityWeighting, :te_totaleffect] - m_nopulse_womarket[:EquityWeighting, :te_totaleffect]) / m_withpulse_womarket[:co2emissions, :ep_CO2emissionpulse]
                        #sccchanges_womarket_disaggregated =  (m_withpulse_womarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                        #                        m_nopulse_womarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_womarket[:co2emissions, :ep_CO2emissionpulse] .-
                        #                        scc_disaggregated
                        # repeat the SCC computation for models without nonmarket damages component
                        global scc_wononmarket = scc - (m_withpulse_wononmarket[:EquityWeighting, :te_totaleffect] - m_nopulse_wononmarket[:EquityWeighting, :te_totaleffect]) / m_withpulse_wononmarket[:co2emissions, :ep_CO2emissionpulse]
                        #sccchanges_wononmarket_disaggregated = (m_withpulse_wononmarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                        #                                            m_nopulse_wononmarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_wononmarket[:co2emissions, :ep_CO2emissionpulse]  .-
                        #                                            scc_disaggregated

                        # repeat the SCC computation for models without SLR damages
                        global scc_woSLR = scc - (m_withpulse_woSLR[:EquityWeighting, :te_totaleffect] - m_nopulse_woSLR[:EquityWeighting, :te_totaleffect]) / m_withpulse_woSLR[:co2emissions, :ep_CO2emissionpulse]
                        #sccchanges_woSLR_disaggregated = (m_withpulse_woSLR[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                        #                                m_nopulse_woSLR[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_woSLR[:co2emissions, :ep_CO2emissionpulse]  .-
                        #                                scc_disaggregated

                        # repeat the SCC computation for models without the discontinuity component
                        global scc_wodisc = scc - (m_withpulse_wodisc[:EquityWeighting, :te_totaleffect] - m_nopulse_wodisc[:EquityWeighting, :te_totaleffect]) / m_withpulse_wodisc[:co2emissions, :ep_CO2emissionpulse]
                        #sccchanges_wodisc_disaggregated = (m_withpulse_wodisc[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                        #                        m_nopulse_wodisc[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_wodisc[:co2emissions, :ep_CO2emissionpulse]  .-
                        #                                scc_disaggregated

                        # write the SCC and the contributions from the components into df_outscc
                        push!(df_outscc, [jj_spec, jj_scen, jj_ge, jj_equiw, jj_gdploss, jj_permafr, jj_gedisc, jj_exp, jj_year,
                                        scc, scc_womarket, scc_wononmarket, scc_woSLR, scc_wodisc,
                                        scc - (scc_womarket + scc_wononmarket + scc_woSLR + scc_wodisc),
                                        sum(scc_disaggregated[:, 1]),
                                        sum(scc_disaggregated[:, 2]),
                                        sum(scc_disaggregated[:, 3]),
                                        sum(scc_disaggregated[:, 4]),
                                        sum(scc_disaggregated[:, 5]),
                                        sum(scc_disaggregated[:, 6]),
                                        sum(scc_disaggregated[:, 7]),
                                        sum(scc_disaggregated[:, 8])])


                    else
                        error("CO2 pulse was not executed correctly. Emissions differ in the second time period or do not have the pre-specified difference in the first.")
                    end

                end
            end
        end
    end
end

# remove the first placeholder row
df_outscc = df_outscc[df_outscc[:scc] .!= -999., :]

# add a column for

# export the SCC and its decomposition for all pulse-year pairs into a csv file
CSV.write(string(dir_output, "MimiPageSCCs.csv"), df_outscc)
