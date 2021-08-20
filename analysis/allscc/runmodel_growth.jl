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

include("main_model_growth.jl")

# define the model regions in the order that Mimi returns stuff
myregions = ["EU", "USA", "Other OECD","Former USSR","China","Southeast Asia","Africa","Latin America"]
myyears = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]

# define the output directory
dir_output = joinpath(@__DIR__, "../../output/")

# define number of Monte Carlo runs
if !@isdefined samplesize
    samplesize = 50000
end

# define the seed
masterseed = 22081994

# define the pulse size
scc_pulse_size = 75000.

################################################################################
################### MC MODEL RUNS    ###########################################
################################################################################

### PART I: results for fixed persistence values

# create a DataFrame where results will be stored
df_sccMC_singleGE = DataFrame(damagePAGE09=false, permafr=false, seaice=false, ge=-999., scen="-999", pulse_size=-999.,
                                 civvalue=-999.,
                                 ge_adapt = -999.,
                                  mean=-999., median=-999., min=-999., max=-999., perc25=-999.,
                                  perc75=-999., sd=-999., varcoeff=-999., perc05=-999., perc95=-999.,
                                  perc10=-999., perc90=-999.,
                                  share_zeroSCC = -999.)

# loop through all relevant parameter combinations and save out results and SCC summary stats
for jj_page09damages in [false] # whether or not to use the market damage function from PAGE09 instead of the new PAGE-ICE function using Burke et al. (2015)
    for jj_permafr in [true] # whether or not to include the permafrost carbon feedback, see Yumashev et al. (2019)
        for jj_seaice in [true] # whether or not to include the surface albedo feedback, see Yumashev et al. (2019)
            for jj_scen in ["RCP4.5 & SSP2"]
                for jj_civvalue in [1., 10.0^20] # whether or not to hold the civilization value damage cap at its default value

                    # skip undesired combinations of parameters
                    if jj_page09damages != false && (jj_permafr != true  || jj_seaice != true || jj_civvalue != 1.)
                        continue
                    elseif jj_permafr != true && (jj_seaice != true || jj_civvalue != 1.)
                        continue
                    elseif jj_permafr != jj_seaice
                        continue
                    end

                    # print the parameter combination to track progress
                    print(string("page09_", jj_page09damages, " Permafr_", jj_permafr, " Scen_", jj_scen, " Seaice_", jj_seaice
                                     ))

                    # loop through the different values for persistence and its decay rate (= adaptation)
                    for jj_ge in [0.0:0.1:1.0;]
                        for jj_geadapt in [0.0:0.005:0.04;]

                            # skip redundant iterations with non-zero adaptation and zero persistence
                            if jj_ge == 0. && jj_geadapt > 0.
                                continue
                            elseif jj_geadapt != 0. && jj_civvalue != 1.
                                continue
                            end

                            # print out the growth effects to track progress
                            print(string("Rho = ", jj_ge, " ge_adapt = ", jj_geadapt))

                            # define the output directory for the Monte Carlo files
                            dir_MCoutput = string(dir_output, "montecarlo-singleGE/scen", jj_scen, "_permafr", jj_permafr, "_seaice", jj_seaice,
                                                            "_page09", jj_page09damages, "/", "ge", jj_ge,
                                                            "_geadapt", jj_geadapt,
                                                            "_civ", jj_civvalue, "/")

                            # fix the seed and calculate the SCC using a triangular distribution collapsing to a single value
                            Random.seed!(masterseed)
                            global scc_mcs_object = get_scc_mcs(samplesize, 2020, dir_MCoutput,
                                                                    scenario=jj_scen,
                                                                    pulse_size=scc_pulse_size,
                                                                    use_permafrost=jj_permafr,
                                                                    use_seaice=jj_seaice,
                                                                    use_page09damages=jj_page09damages,
                                                                    ge_minimum=jj_ge,
                                                                    ge_maximum=jj_ge + 10^(-30),
                                                                    ge_mode=jj_ge,
                                                                    civvalue_multiplier=jj_civvalue,
                                                                    geadrate = jj_geadapt)

                            # write out the full distribution
                            writedlm(string(dir_MCoutput, "SCC_MC.csv"), scc_mcs_object, ",")

                            # write results into the data frame
                            push!(df_sccMC_singleGE, [jj_page09damages, jj_permafr, jj_seaice, jj_ge,
                                                          jj_scen, scc_pulse_size, jj_civvalue,
                                                          jj_geadapt,
                                                          mean(scc_mcs_object[:, 1]),
                                                          median(scc_mcs_object[:, 1]),
                                                          minimum(scc_mcs_object[:, 1]),
                                                          maximum(scc_mcs_object[:, 1]),
                                                          StatsBase.percentile(scc_mcs_object[:, 1], 25),
                                                          StatsBase.percentile(scc_mcs_object[:, 1], 75),
                                                          Statistics.std(scc_mcs_object[:, 1]),
                                                          Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1]),
                                                          StatsBase.percentile(scc_mcs_object[:, 1], 5),
                                                          StatsBase.percentile(scc_mcs_object[:, 1], 95),
                                                          StatsBase.percentile(scc_mcs_object[:, 1], 10),
                                                          StatsBase.percentile(scc_mcs_object[:, 1], 90),
                                                          count(scc_mcs_object .== 0.) / samplesize])

                          # clean out the MCS objects
                            scc_mcs_object = nothing

                        end
                    end
                end
            end
        end
    end
end

# remove the first placeholder row
df_sccMC_singleGE = df_sccMC_singleGE[df_sccMC_singleGE[!, :scen] .!= "-999", :]

# export the results
CSV.write(string(dir_output, "MimiPageGrowthEffectsResults_SCC_fixedGE.csv"), df_sccMC_singleGE)


### PART II: results for the EMPIRICAL persistence distribution

# create a DataFrame where results will be stored
df_sccMC = DataFrame(permafr=false, seaice=false, ge_string="-999", scen="-999",
                                  convergence=-999.,  bound=-999., eqwshare=-999.,
                                  civvalue=-999., pulse=-999., ge_adapt = -999.,
                                  emfeed = -999., switch = -999.,
                                  mean=-999., median=-999., min=-999., max=-999., perc25=-999.,
                                  perc75=-999., sd=-999., varcoeff=-999.,
                                  perc05=-999., perc95=-999., perc10=-999., perc90=-999.,
                                  share_zeroSCC = -999., count_NaN = -999)

# loop through all relevant parameter/scenario combinations and save out results and SCC summary stats
for jj_scen in ["RCP4.5 & SSP2", "RCP2.6 & SSP1", "RCP8.5 & SSP5", "RCP1.9 & SSP1"]
    for jj_gestring in ["EMPIRICAL"] # which persistence distribution to use (use "EMPIRICAL+" for a version where negative persistence draws are trimmed to zero)
        for jj_permafr in [true]
            for jj_seaice in [true]
                for jj_civvalue in [1., 10.0^20]
                    for jj_cbabs in [740.65] # the level of the subsistence boundary for per capita consumption
                        for jj_eqwshare in [0.99, 0.95, 0.999] # the share of per capita consumption until which damages are equity-weighted
                            for jj_convergence in [1., 0.] # whether or not to use the convergence system for the subsistence and equity-weighting thresholds
                                for jj_pulse in [scc_pulse_size] # the size of the CO2 pulse used for SCC calculations
                                    for jj_geadapt in [0.0:0.01:0.05;] # the decay rate of persistence over time
                                        for jj_emfeed in [1., 0.] # whether or not persistence-related GDP reductions cause proportional reductions in emissions
                                            for jj_regionswitch in [0., 1.] # whether or not persistence is only limited to Global South regions

                                        # overwrite jj_geadapt with nothing if its zero (which will triger the deterministic default value of zero)
                                        if jj_geadapt == 0.
                                            jj_geadapt = nothing
                                        end

                                        # skip undesired or infeasible combinations of parameters/scenarios
                                        if jj_scen != "RCP4.5 & SSP2" && (jj_gestring != "EMPIRICAL" || jj_permafr != true ||
                                                                            jj_seaice != true || jj_civvalue != 1. || jj_cbabs != 740.65 ||
                                                                            jj_eqwshare != 0.99 || jj_convergence != 1. || jj_pulse != scc_pulse_size ||
                                                                            jj_geadapt != nothing || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_permafr != jj_seaice
                                            continue
                                        elseif jj_gestring != "EMPIRICAL" && (jj_cbabs != 740.65 || jj_eqwshare != 0.99 || jj_convergence != 1. ||
                                                                                jj_pulse != scc_pulse_size || jj_geadapt != nothing  || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_civvalue != 1. && (jj_cbabs != 740.65 || jj_eqwshare != 0.99 || jj_convergence != 1. ||
                                                                    jj_pulse != scc_pulse_size || jj_geadapt != nothing || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_cbabs != 740.65 && (jj_civvalue != 1. || jj_gestring != "EMPIRICAL" || jj_eqwshare != 0.99 ||
                                                                    jj_convergence != 1. || jj_pulse != scc_pulse_size || jj_geadapt != nothing || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_eqwshare != 0.99 && (jj_civvalue != 1. || jj_gestring != "EMPIRICAL" || jj_convergence != 1. ||
                                                                        jj_pulse != scc_pulse_size || jj_geadapt != nothing || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_convergence != 1. && (jj_civvalue != 1. || jj_gestring != "EMPIRICAL" || jj_pulse != scc_pulse_size ||
                                                                        jj_geadapt != nothing  || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_pulse != scc_pulse_size && (jj_geadapt != nothing  || jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_geadapt != nothing  && (jj_emfeed != 1. || jj_regionswitch != 0.)
                                            continue
                                        elseif jj_emfeed != 1. && jj_regionswitch != 0.
                                            continue
                                        end

                                        # set the ge_string parameters
                                        if jj_gestring == "MILD"
                                            ge_string_min = 0.
                                            ge_string_mode = 0.
                                            ge_string_max = 0.5280681 # value based on converging ratio of marginal impacts from Burke et al regression for 1Lag (temperature and precipitation)
                                            ge_use_empirical = 0.
                                        elseif jj_gestring == "MEDIUM"
                                            ge_string_min = 0.
                                            ge_string_mode = 0.5280681
                                            ge_string_max = 1.
                                            ge_use_empirical = 0.
                                        elseif jj_gestring == "EMPIRICAL" # note: for EMPIRICAL and EMPIRICAL+, the triangular will be overwritten by draws from the empirical distribution
                                            ge_string_min = 0.
                                            ge_string_mode = 0.
                                            ge_string_max = 0.0001
                                            ge_use_empirical = 1.
                                        elseif jj_gestring == "EMPIRICAL+"
                                            ge_string_min = 0.
                                            ge_string_mode = 0.
                                            ge_string_max = 0.0001
                                            ge_use_empirical = 2.
                                        end

                                        # print out the parameters to track progress
                                        print(string("Scen_", jj_scen, " Ge-mode_", jj_gestring,
                                                     " Permafr_", jj_permafr, " Seaice_", jj_seaice, " Civvalue_", jj_civvalue,
                                                     " cbabs_", jj_cbabs, " eqwshare_", jj_eqwshare,
                                                     " convergence", jj_convergence, "pulse_", jj_pulse,
                                                     " geadapt", jj_geadapt, " emfeed", jj_emfeed,
                                                     " switch", jj_regionswitch))

                                        # define the output directory for the Monte Carlo files
                                        dir_MCoutput = string(dir_output, "mc_diGE/ge", jj_gestring,
                                                                        "_scen", jj_scen,
                                                                        "_pf", jj_permafr,
                                                                        "_se", jj_seaice,
                                                                        "_co", jj_convergence, "_bd", jj_cbabs, "_eq", jj_eqwshare,
                                                                        "_ci", jj_civvalue,
                                                                        "_p", jj_pulse,
                                                                        "_gead", jj_geadapt,
                                                                        "_emfe", jj_emfeed,
                                                                        "_sw", jj_regionswitch,
                                                                         "/")

                                        # calculate the MC SCC
                                        Random.seed!(masterseed)
                                        global scc_mcs_object = get_scc_mcs(samplesize, 2020, dir_MCoutput,
                                                                            scenario=jj_scen,
                                                                            pulse_size=jj_pulse,
                                                                            use_permafrost=jj_permafr,
                                                                            use_seaice=jj_seaice,
                                                                            use_page09damages=false,
                                                                            ge_minimum=ge_string_min,
                                                                            ge_maximum=ge_string_max,
                                                                            ge_mode=ge_string_mode,
                                                                            ge_use_empirical=ge_use_empirical,
                                                                            civvalue_multiplier=jj_civvalue,
                                                                            use_convergence=jj_convergence,
                                                                            cbabs=jj_cbabs,
                                                                            eqwbound=jj_eqwshare,
                                                                            geadrate = jj_geadapt,
                                                                            emfeedback = jj_emfeed,
                                                                            ge_use_switch = jj_regionswitch
                                                                            )

                                        # write out the full distribution
                                        writedlm(string(dir_MCoutput, "SCC_MC.csv"),
                                                                scc_mcs_object, ",")

                                        # create a NaN-free version of the SCC distribution
                                        scc_mcs_object = filter(!isnan, scc_mcs_object)

                                        # push the results into the data frame
                                        push!(df_sccMC, [jj_permafr, jj_seaice, jj_gestring,  jj_scen,
                                                        jj_convergence,  jj_cbabs, jj_eqwshare,
                                                        jj_civvalue, jj_pulse,
                                                        ifelse(jj_geadapt == nothing, 0., jj_geadapt),
                                                        jj_emfeed, jj_regionswitch,
                                                        mean(scc_mcs_object[:, 1]),
                                                        median(scc_mcs_object[:, 1]),
                                                        minimum(scc_mcs_object[:, 1]),
                                                        maximum(scc_mcs_object[:, 1]),
                                                        StatsBase.percentile(scc_mcs_object[:, 1], 25),
                                                        StatsBase.percentile(scc_mcs_object[:, 1], 75),
                                                        Statistics.std(scc_mcs_object[:, 1]),
                                                        Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1]),
                                                        StatsBase.percentile(scc_mcs_object[:, 1], 5),
                                                        StatsBase.percentile(scc_mcs_object[:, 1], 95),
                                                        StatsBase.percentile(scc_mcs_object[:, 1], 10),
                                                        StatsBase.percentile(scc_mcs_object[:, 1], 90),
                                                        count(scc_mcs_object .== 0.) / length(scc_mcs_object),
                                                        samplesize - length(scc_mcs_object)])

                                        # clean out the scc_mcs_object
                                        global scc_mcs_object = nothing
                                        ge_string_min = nothing
                                        ge_string_max = nothing
                                        ge_string_mode = nothing

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
end

# remove the first placeholder row
df_sccMC = df_sccMC[df_sccMC[!, :scen] .!= "-999", :]

# export the results
CSV.write(string(dir_output, "MimiPageGrowthEffectsResultsMonteCarlo.csv"), df_sccMC)


### PART III: run the default scenario/parameter settings with an empirical persistence distribution derived from low-pass filtering climate vars

# rerun the main settings for an empirical distribution that is derived from low-pass filtering climate variables
include("main_model_growth_lowpass.jl")

# set the output directory for MC results
dir_MCoutput = string(dir_output, "lowpassfiltered_persistence/")

# calculate the stochastic mean SCC using the default parameter & scenario settings
Random.seed!(masterseed)
global scc_mcs_object = get_scc_mcs(samplesize, 2020, dir_MCoutput,
                                    scenario="RCP4.5 & SSP2",
                                    pulse_size=scc_pulse_size,
                                    use_permafrost=true,
                                    use_seaice=true,
                                    use_page09damages=false,
                                    ge_minimum=0.,
                                    ge_maximum=0.0001,
                                    ge_mode=0.,
                                    ge_use_empirical=1.,
                                    civvalue_multiplier=1.,
                                    use_convergence= 1.,
                                    cbabs=740.65,
                                    eqwbound=0.99,
                                    geadrate = 0.,
                                    emfeedback = 1.,
                                    ge_use_switch = 0.
                                    )

# # write out the full distribution
writedlm(string(dir_MCoutput, "SCC_MC.csv"),
                        scc_mcs_object, ",")

# clean out
global scc_mcs_object = nothing
