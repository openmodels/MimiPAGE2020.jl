
using Test

m = page_model()
include("../src/components/RCPSSPScenario.jl")
include("../src/components/CO2emissions.jl")

scenario = addrcpsspscenario(m, "NDCs")
co2emit = add_comp!(m, co2emissions)

co2emit[:er_CO2emissionsgrowth] = scenario[:er_CO2emissionsgrowth]
set_param!(m, :co2emissions, :e0_baselineCO2emissions, readpagedata(m,"data/e0_baselineCO2emissions.csv"))
set_param!(m, :co2emissions, :er_CO2emissionsgrowth, readpagedata(m, "data/er_CO2emissionsgrowth.csv"))

##running Model
run(m)

emissions= m[:co2emissions,  :e_regionalCO2emissions]

# Recorded data
emissions_compare=readpagedata(m, "test/validationdata/e_regionalCO2emissions.csv")

@test emissions ≈ emissions_compare rtol=1e-3
