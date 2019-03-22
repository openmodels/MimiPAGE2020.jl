
using Test

m = page_model()
include("../src/components/RCPSSPScenario.jl")
include("../src/components/LGemissions.jl")

scenario = add_comp!(m, RCPSSPScenario)
lgemit = add_comp!(m, LGemissions)

scenario[:ssp] = "rcp85"

lgemit[:er_LGemissionsgrowth] = scenario[:er_LGemissionsgrowth]
set_param!(m, :LGemissions, :e0_baselineLGemissions, readpagedata(m,"data/e0_baselineLGemissions.csv"))
set_param!(m, :LGemissions, :er_LGemissionsgrowth, readpagedata(m, "data/er_LGemissionsgrowth.csv"))

# run Model
run(m)

emissions= m[:LGemissions,  :e_regionalLGemissions]
emissions_compare=readpagedata(m, "test/validationdata/e_regionalLGemissions.csv")

@test emissions ≈ emissions_compare rtol=1e-3
