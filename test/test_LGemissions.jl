using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/LGemissions.jl")

    rcpsspscenario = addrcpsspscenario(m, scenario)
    lgemit = add_comp!(m, LGemissions)

    lgemit[:er_LGemissionsgrowth] = rcpsspscenario[:er_LGemissionsgrowth]
    set_param!(m, :LGemissions, :e0_baselineLGemissions, readpagedata(m,"data/e0_baselineLGemissions.csv"))

    # run Model
    run(m)

    emissions= m[:LGemissions,  :e_globalLGemissions]
    emissions_compare=readpagedata(m, "test/validationdata/$valdir/e_globalLGemissions.csv")

    @test emissions ≈ emissions_compare rtol=1e-3
end
