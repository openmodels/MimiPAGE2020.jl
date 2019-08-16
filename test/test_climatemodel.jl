using Test

include("../src/climate_model.jl")

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = climatemodel(scenario, use_permafrost, use_seaice)

    rt_g = m[:ClimateTemperature, :rt_g_globaltemperature]
    rt_g_compare = readpagedata(m, "test/validationdata/$valdir/rt_g_globaltemperature.csv")

    @test rt_g ≈ rt_g_compare rtol=1e-3
end
