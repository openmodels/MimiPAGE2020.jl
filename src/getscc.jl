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
scc_pulse = 10^(0)
m1 = getpage()
run(m1)

# compute SCC
if m1[:co2emissions, :e_globalCO2emissions][1] == m[:co2emissions, :e_globalCO2emissions][1] + m1[:co2emissions, :ep_CO2emissionpulse] && m1[:co2emissions, :e_globalCO2emissions][2] == m[:co2emissions, :e_globalCO2emissions][2]
    # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
    scc = (m1[:EquityWeighting, :te_totaleffect] - m[:EquityWeighting, :te_totaleffect]) / m1[:co2emissions, :ep_CO2emissionpulse]
    # Note: disaggregation does not work as abatement costs are driven by baseline emissions and growth rate, not by levels at time t
    scc_imp = (m1[:EquityWeighting, :td_totaldiscountedimpacts] - m[:EquityWeighting, :td_totaldiscountedimpacts]) / m1[:co2emissions, :ep_CO2emissionpulse]
    scc_adt = (m1[:EquityWeighting, :tac_totaladaptationcosts] - m[:EquityWeighting, :tac_totaladaptationcosts]) / m1[:co2emissions, :ep_CO2emissionpulse]
    scc_abm = (m1[:EquityWeighting, :tpc_totalaggregatedcosts] - m[:EquityWeighting, :tpc_totalaggregatedcosts]) / m1[:co2emissions, :ep_CO2emissionpulse]

    scc_region = Array{Float64}(undef, 8)

    # sum the regional discounted impacts up over time and compute regional SCCs
    for jj in 1:8
        scc_region[jj] = (sum(m1[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, jj]) -
                            sum(m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][:, jj])) / m1[:co2emissions, :ep_CO2emissionpulse]
    end

    if round(sum(scc_region[:]), digits = 2) != round(scc_imp, digits = 2)
        error("Summed regional SCCs do not equal global SCC")
    end
else
    error("CO2 pulse was not executed correctly. Emissions differ in the second time period or do not have the pre-specified difference in the first.")
end

# reset the pulse to zero
scc_pulse = 0
