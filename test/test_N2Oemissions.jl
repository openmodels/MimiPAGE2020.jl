
using Test

m = page_model()
include("../src/components/RCPSSPScenario.jl")
include("../src/components/N2Oemissions.jl")

scenario = add_comp!(m, RCPSSPScenario)
n2oemit = add_comp!(m, n2oemissions)

scenario[:ssp] = "rcp85"

n2oemit[:er_N2Oemissionsgrowth] = scenario[:er_N2Oemissionsgrowth]
set_param!(m, :n2oemissions, :e0_baselineN2Oemissions, readpagedata(m,"data/e0_baselineN2Oemissions.csv"))
set_param!(m, :n2oemissions, :er_N2Oemissionsgrowth, readpagedata(m, "data/er_N2Oemissionsgrowth.csv"))

##running Model
run(m)

# Generated data
emissions= m[:n2oemissions,  :e_regionalN2Oemissions]
# Recorded data
emissions_compare=readpagedata(m, "test/validationdata/e_regionalN2Oemissions.csv")

@test emissions ≈ emissions_compare rtol=1e-3
