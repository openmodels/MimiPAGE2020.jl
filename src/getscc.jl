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
scc_pulse = 1
m1 = getpage()
run(m1)

# empty the scc parameter to make sure it does not affect future model runs
scc_pulse = nothing

# compute
if m1[:co2emissions, :e_globalCO2emissions][1] - m[:co2emissions, :e_globalCO2emissions][1] == 1 && m1[:co2emissions, :e_globalCO2emissions][2] == m[:co2emissions, :e_globalCO2emissions][2]
    # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
    scc = (m1[:EquityWeighting, :te_totaleffect] - m[:EquityWeighting, :te_totaleffect])
else
    error("CO2 pulse was not executed correctly. t=1 emissions do not differ by 1 or t = 2 emissions do not equal")
end
