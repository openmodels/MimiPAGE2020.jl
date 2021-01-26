using Test
using MimiPAGE2020: n2oemissions

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = test_page_model()

    scenario = addrcpsspscenario(m, scenario)
    n2oemit = add_comp!(m, n2oemissions)

    n2oemit[:er_N2Oemissionsgrowth] = scenario[:er_N2Oemissionsgrowth]
    set_param!(m, :n2oemissions, :e0_baselineN2Oemissions, readpagedata(m, "data/e0_baselineN2Oemissions.csv"))

    ##running Model
    run(m)

    # Generated data
    emissions = m[:n2oemissions,  :e_regionalN2Oemissions]
    # Recorded data
    emissions_compare = readpagedata(m, "test/validationdata/$valdir/e_regionalN2Oemissions.csv")

    @test emissions ≈ emissions_compare rtol = 1e-3
end
