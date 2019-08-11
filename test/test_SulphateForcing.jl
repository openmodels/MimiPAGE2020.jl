using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/SulphateForcing.jl")

    scenario = addrcpsspscenario(m, scenario)
    sulfemit = add_comp!(m, SulphateForcing)

    sulfemit[:pse_sulphatevsbase] = scenario[:pse_sulphatevsbase]

    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)

    forcing=m[:SulphateForcing,:fs_sulphateforcing]
    forcing_compare=readpagedata(m,"test/validationdata/$valdir/fs_sulfateforcing.csv")

    @test forcing ≈ forcing_compare rtol=1e-3
end
