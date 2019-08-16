using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/GDP.jl")

    rcpsspscenario = addrcpsspscenario(m, "NDCs")
    gdp = add_comp!(m, GDP)

    gdp[:grw_gdpgrowthrate] = rcpsspscenario[:grw_gdpgrowthrate]
    gdp[:pop0_initpopulation] = readpagedata(m, "data/pop0_initpopulation.csv")
    gdp[:pop_population] = readpagedata(m, "test/validationdata/$valdir/pop_population.csv")
    gdp[:y_year] = Mimi.dim_keys(m.md, :time)
    gdp[:y_year_0] = 2015.

    p=load_parameters(m)
    set_leftover_params!(m,p)

    # run model
    run(m)

    # Generated data
    gdp = m[:GDP, :gdp]

    # Recorded data
    gdp_compare = readpagedata(m, "test/validationdata/$valdir/gdp.csv")

    @test gdp ≈ gdp_compare rtol=100

    cons_percap_consumption_0_compare = readpagedata(m, "test/validationdata/cons_percap_consumption_0.csv")
    @test m[:GDP, :cons_percap_consumption_0] ≈ cons_percap_consumption_0_compare rtol=1e-2
end
