using Test

Mimi.reset_compdefs()

include("../src/getpagefunction.jl")
m = getpage("NDCs", false, false)
run(m)

while m[:Discontinuity,:occurdis_occurrencedummy] != [0.,0.,0.,0.,0.,0.,0.,1.,1.,1.]
    run(m)
end

# Climate component
temp = m[:ClimateTemperature, :rt_g_globaltemperature]
temp_compare = readpagedata(m,"test/validationdata/noperm/rt_g_globaltemperature.csv")
@test temp ≈ temp_compare rtol=1e-4

# Abatement Costs
abatement = m[:TotalAbatementCosts, :tct_totalcosts]
abatement_compare = readpagedata(m,"test/validationdata/noperm/tct_totalcosts.csv")
@test abatement ≈ abatement_compare rtol=1e-2

te = m[:EquityWeighting, :te_totaleffect]
te_compare = 9.462179758012009e8
@test te ≈ te_compare rtol=1e4
