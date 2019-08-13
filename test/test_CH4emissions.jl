
for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/CH4emissions.jl")

    scenario = addrcpsspscenario(m, scenario)
    ch4emit = add_comp!(m, ch4emissions)

    ch4emit[:er_CH4emissionsgrowth] = scenario[:er_CH4emissionsgrowth]
    set_param!(m, :ch4emissions, :e0_baselineCH4emissions, readpagedata(m, "data/e0_baselineCH4emissions.csv")) #PAGE 2009 documentation pp38

    ##running Model
    run(m)

    # Generated data
    emissions= m[:ch4emissions,  :e_regionalCH4emissions]

    # Recorded data
    emissions_compare=readpagedata(m, "test/validationdata/$valdir/e_regionalCH4emissions.csv")

    @test emissions ≈ emissions_compare rtol=1e-3
end
