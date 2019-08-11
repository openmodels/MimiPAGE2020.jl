using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/CH4forcing.jl")

    add_comp!(m, ch4forcing, :ch4forcing)

    set_param!(m, :ch4forcing, :c_N2Oconcentration, readpagedata(m,"test/validationdata/$valdir/c_n2oconcentration.csv"))
    set_param!(m, :ch4forcing, :c_CH4concentration, readpagedata(m,"test/validationdata/$valdir/c_ch4concentration.csv"))

    ##running Model
    run(m)

    @test !isnan(m[:ch4forcing, :f_CH4forcing][10])

    forcing=m[:ch4forcing,:f_CH4forcing]
    forcing_compare=readpagedata(m,"test/validationdata/$valdir/f_ch4forcing.csv")

    @test forcing ≈ forcing_compare rtol=1e-3
end
