################################################################################
###################### RUN MODELS MANUALLY  ####################################
################################################################################

using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random

include("main_model.jl")
include("mcs.jl")

# clean the master parameters and get the model for the chosen scenario
m = getpage("RCP4.5 & SSP2")
run(m)
m[:EquityWeighting, :te_totaleffect]
compute_scc(m, year = 2020)

update_param!(m, :use_convergence, 0.)
run(m)
compute_scc(m, year = 2020)

update_param!(m, :ge_growtheffects, 1.)
update_param!
run(m)
m[:EquityWeighting, :te_totaleffect]
compute_scc(m, year = 2020)

update_param!(m, :lossinc_includegdplosses, 1.)       # whether to include counterfactual losses in damages, defaults o 0. (= no)
run(m)
m[:EquityWeighting, :te_totaleffect]
compute_scc(m, year = 2020)

update_param!(m, :civvalue_civilizationvalue, m[:EquityWeighting, :civvalue_civilizationvalue]*10^9) # relax the civilization value constraint
run(m)
m[:EquityWeighting, :te_totaleffect]
compute_scc(m, year = 2020)
# update all parameters of interest
                       # persistence parameter for growth effects, defaults to 1
# update_param!(m, :equity_proportion, 0.)                      # whether equity weighting is applied (1.) or not (0.), defaults to 1.
# update_param!(m, :cbshare_pcconsumptionboundshare, 10)        # the share of 2015 EU consumption for lower bound, defaults to 5 (unit: %)
# update_param!(m, :eqwshare_shareofweighteddamages, 0.99)      # the share of consumption that is equity-weighted, defaults to 0.99
# update_param!(m, :discfix_fixediscountrate, jj_disc)          # whether an exogenous fixed discount rate is used;
                                                                # (0. = no, otherwise 3., 5. or 7. for rates), defaults to 0.
update_param!(m, :lossinc_includegdplosses, 1.)       # whether to include counterfactual losses in damages, defaults o 0. (= no)

run(m)
explore(m)

writedlm(string(dir_output, "lgdp_gdploss_gdp_scenNDCs_ge", m[:GDP, :ge_growtheffects], "_modelspecRegionBayes_permafrYes_bound", m[:GDP, :cbshare_pcconsumptionboundshare], ".csv"),
            hcat(["year"; myyears], [permutedims(myregions); m[:GDP, :lgdp_gdploss]]), ",")

########################## RUN MONTE CARLOS ####################################
Random.seed!(22081994)
mean(get_scc_mcs(2000, 2020, ge_minimum = 0., ge_maximum = 0.1, ge_mode = 0., civvalue_multiplier = 10.0^20))
Random.seed!(22081994)
mean(get_scc_mcs(2000, 2020, ge_minimum = 0., ge_maximum = 0.1, ge_mode = 0., use_convergence = 0., civvalue_multiplier = 10.0^20))
Random.seed!(22081994)
mean(get_scc_mcs(2000, 2020, ge_minimum = 0., ge_maximum = 0.1, ge_mode = 0., cbshare = 5., civvalue_multiplier = 10.0^20))


scc_lowdistribution = get_scc_mcs_ge(500, 2020, dir_output, gdpincl = 1., ge_min = 0., ge_mode = 0., ge_max = 1.)
mean(scc_lowdistribution)
include("mcs.jl")
Random.seed!(1)
scc_middledistribution = get_scc_mcs_custom(500, 2020, dir_output, gdpincl = 1.)
mean(scc_middledistribution)
include("mcs.jl")
scc_highdistribution = get_scc_mcs_custom(500, 2020, dir_output, gdpincl = 1.)
mean(scc_highdistribution)



################################################################################
################ MANUALLY RUN A MONTE CARLO BATCH ##############################
################################################################################

# set the parameters
dir_output = "C:/Users/nasha/Documents/GitHub/damage-regressions/data/mimi-page-output_Dec19/"

jj_gestring = "MEDIUM"
jj_scen = "RCP4.5 & SSP2"
jj_page09damages = false
jj_permafr = true
jj_seaice = true
jj_convergence = 1.
jj_consbound = 1.
jj_eqwshare = 0.99
jj_civvalue = 10.0^20
jj_pulse = 75000.
masterseed = 22081994
numberofmontecarlo = 50000

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

dir_MCoutput = string(dir_output, "montecarlo_distrGE/ge", jj_gestring,
                                "_scen", jj_scen,
                                "_per", jj_permafr,
                                "_sea", jj_seaice,
                                "_conv", jj_convergence, "_boun", jj_consbound, "_eqw", jj_eqwshare,
                                "_civ", jj_civvalue,
                                "_pul", jj_pulse,
                                 "/")

# calculate the stochastic mean SCC
Random.seed!(masterseed)
global scc_mcs_object = get_scc_mcs(numberofmontecarlo, 2020, dir_MCoutput,
                                    scenario = jj_scen,
                                    pulse_size = jj_pulse,
                                    use_permafrost = jj_permafr,
                                    use_seaice = jj_seaice,
                                    use_page09damages = jj_page09damages,
                                    ge_minimum = ge_string_min,
                                    ge_maximum = ge_string_max,
                                    ge_mode = ge_string_mode,
                                    civvalue_multiplier = jj_civvalue,
                                    cbshare = jj_consbound,
                                    use_convergence = jj_convergence,
                                    eqwbound = jj_eqwshare)
