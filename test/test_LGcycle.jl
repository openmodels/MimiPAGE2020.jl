using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/LGcycle.jl")

    add_comp!(m, LGcycle)

    set_param!(m, :LGcycle, :e_globalLGemissions, readpagedata(m,"test/validationdata/$valdir/e_globalLGemissions.csv"))
    set_param!(m, :LGcycle, :y_year, [2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.]) #real value
    set_param!(m, :LGcycle, :y_year_0, 2015.) #real value
    set_param!(m, :LGcycle, :rtl_g_landtemperature, readpagedata(m,"test/validationdata/$valdir/rtl_g_landtemperature.csv"))

    p=load_parameters(m)
    set_leftover_params!(m,p) #important for setting left over component values

    # run Model
    run(m)

    conc=m[:LGcycle,  :c_LGconcentration]
    conc_compare=readpagedata(m,"test/validationdata/$valdir/c_LGconcentration.csv")

    @test conc ≈ conc_compare rtol=1e-4
end
