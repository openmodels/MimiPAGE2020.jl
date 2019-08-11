using Test

include("../src/components/CO2cycle.jl")

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    addco2cycle(m, use_permafrost)

    set_param!(m, :CO2Cycle, :e_globalCO2emissions, readpagedata(m, "test/validationdata/$valdir/e_globalCO2emissions.csv"))
    set_param!(m, :CO2Cycle, :permte_permafrostemissions, readpagedata(m, "test/validationdata/$valdir/perm_tot_e_co2.csv"))
    set_param!(m, :CO2Cycle, :y_year,[2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.])#real values
    set_param!(m, :CO2Cycle, :y_year_0, 2015.)#real value
    set_param!(m, :CO2Cycle, :rt_g_globaltemperature, readpagedata(m, "test/validationdata/$valdir/rt_g_globaltemperature.csv"))
    p=load_parameters(m)
    set_leftover_params!(m,p) #important for setting left over component values
    ##running Model
    run(m)

    te = m[:CO2Cycle, :te_totalemissions]
    te_compare = readpagedata(m, "test/validationdata/$valdir/total_e_co2.csv")
    @test te ≈ te_compare rtol=1e-4

    asymp = m[:CO2Cycle, :asymptote_co2_proj]
    asymp_compare = readpagedata(m, "test/validationdata/$valdir/asymp_comp_co2_proj.csv")
    @test asymp ≈ asymp_compare rtol=1e-4

    oceanlong = m[:CO2Cycle, :ocean_long_uptake_component_proj]
    oceanlong_compare = readpagedata(m, "test/validationdata/$valdir/ocean_long_comp_co2_proj.csv")
    @test oceanlong ≈ oceanlong_compare rtol=1e-4

    renoccff = m[:CO2Cycle, :renoccf_remainCO2wocc]
    renoccff_compare = readpagedata(m, "test/validationdata/$valdir/re_co2_no_ccff.csv")
    @test renoccff ≈ renoccff_compare rtol=1e-4

    co2conc = m[:CO2Cycle,  :c_CO2concentration]
    co2conc_compare = readpagedata(m, "test/validationdata/$valdir/c_co2concentration.csv")

    @test co2conc ≈ co2conc_compare rtol=1e-4
end
