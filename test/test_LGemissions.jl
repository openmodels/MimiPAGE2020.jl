
using Test

m = page_model()
include("../src/components/RCPSSPScenario.jl")
include("../src/components/LGemissions.jl")

scenario = addrcpsspscenario(m, "NDCs")
lgemit = add_comp!(m, LGemissions)

lgemit[:er_LGemissionsgrowth] = scenario[:er_LGemissionsgrowth]
set_param!(m, :LGemissions, :e0_baselineLGemissions, readpagedata(m,"data/e0_baselineLGemissions.csv"))

# run Model
run(m)

emissions= m[:LGemissions,  :e_regionalLGemissions]
emissions_compare=readpagedata(m, "test/validationdata/e_regionalLGemissions.csv")

@test emissions ≈ emissions_compare rtol=1e-3
