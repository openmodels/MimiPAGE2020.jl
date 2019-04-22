
using Test

m = page_model()
include("components/RCPSSPScenario.jl")
include("../src/components/Population.jl")

scenario = addrcpsspscenario(m, "NDCs")
population = addpopulation(m)

population[:y_year_0] = 2015.
population[:y_year] = Mimi.dim_keys(m.md, :time)
population[:popgrw_populationgrowth] = scenario[:popgrw_populationgrowth]

p = load_parameters(m)

set_leftover_params!(m, p)

run(m)

# Generated data
pop = m[:Population, :pop_population]

# Recorded data
pop_compare = readpagedata(m, "test/validationdata/pop_population.csv")

@test pop ≈ pop_compare rtol=1e-3
