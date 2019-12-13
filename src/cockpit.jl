################################################################################
###################### RUN MODELS MANUALLY  ####################################
################################################################################

using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV

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

include("mcs.jl")
Random.seed!(1)
get_scc_mcs(10, 2020)
get_scc_mcs_ge(10, 2020, ge_minimum = 0.,)

get_scc_mcs_ge(10, 2020, ge_minimum = 0., ge_maximum = 1., ge_mode = 0.5)

scc_lowdistribution = get_scc_mcs_ge(500, 2020, dir_output, gdpincl = 1., ge_min = 0., ge_mode = 0., ge_max = 1.)
mean(scc_lowdistribution)
include("mcs.jl")
Random.seed!(1)
scc_middledistribution = get_scc_mcs_custom(500, 2020, dir_output, gdpincl = 1.)
mean(scc_middledistribution)
include("mcs.jl")
scc_highdistribution = get_scc_mcs_custom(500, 2020, dir_output, gdpincl = 1.)
mean(scc_highdistribution)
