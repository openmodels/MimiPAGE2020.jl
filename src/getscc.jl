using Mimi
using Distributions
using CSVFiles
using DataFrames

include("getpagefunction.jl")
include("utils/mctools.jl")

# set the pulse parameter zero, i.e. no pulse and compute the model
scc_pulse = 0
m = getpage()
run(m)

# create a model with pulse of +1MT CO2 at t = 1
scc_pulse = 10^(-6)
m1 = getpage()
run(m1)

# compute SCC
if m1[:co2emissions, :e_globalCO2emissions][2] == m[:co2emissions, :e_globalCO2emissions][2]
    # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
    scc = (m1[:EquityWeighting, :te_totaleffect] - m[:EquityWeighting, :te_totaleffect]) / scc_pulse
    # Note: disaggregation does not work as abatement costs are driven by baseline emissions and growth rate, not by levels at time t
    scc_imp = (m1[:EquityWeighting, :td_totaldiscountedimpacts] - m[:EquityWeighting, :td_totaldiscountedimpacts]) / scc_pulse
    scc_adt = (m1[:EquityWeighting, :tac_totaladaptationcosts] - m[:EquityWeighting, :tac_totaladaptationcosts]) / scc_pulse
    scc_abm = (m1[:EquityWeighting, :tpc_totalaggregatedcosts] - m[:EquityWeighting, :tpc_totalaggregatedcosts]) / scc_pulse
else
    error("CO2 pulse was not executed correctly. Emissions differ in the second time period.")
end

# empty the scc parameter to make sure it does not affect future model runs
scc_pulse = nothing
