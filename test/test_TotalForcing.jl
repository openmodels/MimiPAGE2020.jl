using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/TotalForcing.jl")

    scenario = addrcpsspscenario(m, scenario)
    totalforcing = add_comp!(m, TotalForcing)

    totalforcing[:f_CO2forcing] = readpagedata(m,"test/validationdata/$valdir/f_co2forcing.csv")
    totalforcing[:f_CH4forcing] = readpagedata(m,"test/validationdata/$valdir/f_ch4forcing.csv")
    totalforcing[:f_N2Oforcing] = readpagedata(m,"test/validationdata/$valdir/f_n2oforcing.csv")
    totalforcing[:f_lineargasforcing] = readpagedata(m,"test/validationdata/$valdir/f_LGforcing.csv")
    totalforcing[:exf_excessforcing] = scenario[:exf_excessforcing]
    totalforcing[:fs_sulfateforcing] = readpagedata(m, "test/validationdata/$valdir/fs_sulfateforcing.csv")

    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)

    forcing=m[:TotalForcing, :ft_totalforcing]
    forcing_compare=readpagedata(m,"test/validationdata/$valdir/ft_totalforcing.csv")

    @test forcing ≈ forcing_compare rtol=1e-3
end
