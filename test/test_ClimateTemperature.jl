using Test

for testscen in 1:2
    valdir, scenario, use_permafrost = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/ClimateTemperature.jl")

    climatetemperature = add_comp!(m, ClimateTemperature)

    climatetemperature[:y_year_0] = 2015.
    climatetemperature[:y_year] = Mimi.dim_keys(m.md, :time)

    climatetemperature[:ft_totalforcing] = readpagedata(m, "test/validationdata/$valdir/ft_totalforcing.csv")
    climatetemperature[:fs_sulfateforcing] = readpagedata(m, "test/validationdata/$valdir/fs_sulfateforcing.csv")

    p = load_parameters(m)
    set_leftover_params!(m, p)

    ##running Model
    run(m)

    rtl = m[:ClimateTemperature, :rtl_realizedtemperature]
    rtl_compare = readpagedata(m, "test/validationdata/$valdir/rtl_realizedtemperature.csv")

    @test rtl ≈ rtl_compare rtol=1e-5

    rto = m[:ClimateTemperature, :rto_g_oceantemperature]
    rto_compare = readpagedata(m, "test/validationdata/$valdir/rto_g_oceantemperature.csv")

    @test rto ≈ rto_compare rtol=1e-5
end

