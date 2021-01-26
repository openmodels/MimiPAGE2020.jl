using Test
using MimiPAGE2020: co2forcing

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = test_page_model()

    add_comp!(m, co2forcing)

    set_param!(m, :co2forcing, :c_CO2concentration, readpagedata(m, "test/validationdata/$valdir/c_co2concentration.csv"))

    ##running Model
    run(m)

    forcing = m[:co2forcing,:f_CO2forcing]
    forcing_compare = readpagedata(m, "test/validationdata/$valdir/f_co2forcing.csv")

    @test forcing ≈ forcing_compare rtol = 1e-3
end

