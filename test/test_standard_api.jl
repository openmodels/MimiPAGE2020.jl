using Test
using Mimi

@testset "Standard API" begin

# Test that the function does not error and returns a valid value
scc1 = compute_scc(year=2020)
@test scc1 isa Float64

# Test that a higher discount rate makes a lower scc value
scc2 = compute_scc(year=2020, eta=0., prtp=0.03)
@test scc2 < scc1

# Test with a modified model
m = get_model()
update_param!(m, :tcr_transientresponse, 3)
scc3 = compute_scc(m, year=2020)
@test scc3 > scc1

# Test get_marginal_model
mm = get_marginal_model(year = 2040)
mm[:ClimateTemperature, :rt_g_globaltemperature]

# Test compute_scc_mm
result = compute_scc_mm(year=2050)
@test result.scc > scc1
@test result.mm isa Mimi.MarginalModel

end
