using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/CH4cycle.jl")

    addch4cycle(m, use_permafrost)

    set_param!(m, :CH4Cycle, :e_globalCH4emissions, readpagedata(m,"test/validationdata/$valdir/e_globalCH4emissions.csv"))
    set_param!(m, :CH4Cycle, :rtl_g_landtemperature, readpagedata(m,"test/validationdata/$valdir/rtl_g_landtemperature.csv"))
    set_param!(m, :CH4Cycle, :permtce_permafrostemissions, readpagedata(m,"test/validationdata/$valdir/perm_tot_ce_ch4.csv"))
    set_param!(m,:CH4Cycle,:y_year_0,2015.)

    p = load_parameters(m)
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    #running Model
    run(m)

    conc=m[:CH4Cycle,  :c_CH4concentration]
    conc_compare=readpagedata(m,"test/validationdata/$valdir/c_ch4concentration.csv")

    @test conc ≈ conc_compare rtol=1e-4
end
