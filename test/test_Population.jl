using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/Population.jl")

    scenario = addrcpsspscenario(m, scenario)
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
    pop_compare = readpagedata(m, "test/validationdata/$valdir/pop_population.csv")

    @test pop ≈ pop_compare rtol=1e-3
end
