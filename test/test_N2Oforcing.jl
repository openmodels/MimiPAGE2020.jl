using Test
using MimiPAGE2020: n2oforcing

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = test_page_model()

    add_comp!(m, n2oforcing)

    set_param!(m, :n2oforcing, :c_N2Oconcentration, readpagedata(m, "test/validationdata/$valdir/c_n2oconcentration.csv"))
    set_param!(m, :n2oforcing, :c_CH4concentration, readpagedata(m, "test/validationdata/$valdir/c_ch4concentration.csv"))

    ##running Model
    run(m)

    forcing = m[:n2oforcing,:f_N2Oforcing]
    forcing_compare = readpagedata(m, "test/validationdata/$valdir/f_n2oforcing.csv")

    @test forcing ≈ forcing_compare rtol = 1e-3
end
