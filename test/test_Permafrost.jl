using Test

for testscen in 1:2
    valdir, scenario, use_permafrost = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/PermafrostSiBCASA.jl")
    include("../src/components/PermafrostJULES.jl")
    include("../src/components/PermafrostTotal.jl")

    permafrost_sibcasa = add_comp!(model, PermafrostSiBCASA)
    permafrost_jules = add_comp!(model, PermafrostJULES)
    permafrost_total = add_comp!(model, PermafrostTotal)

    permafrost_total[:perm_sib_ce_co2] = permafrost_sibcasa[:perm_sib_ce_co2]
    permafrost_total[:perm_sib_c_co2] = permafrost_sibcasa[:perm_sib_c_co2]
    permafrost_total[:perm_sib_ce_ch4] = permafrost_sibcasa[:perm_sib_ce_ch4]
    permafrost_total[:perm_jul_ce_co2] = permafrost_jules[:perm_jul_ce_co2]
    permafrost_total[:perm_jul_c_co2] = permafrost_jules[:perm_jul_c_co2]
    permafrost_total[:perm_jul_ce_ch4] = permafrost_jules[:perm_jul_ce_ch4]

    set_param!(m, :PermafrostSiBCASA, :rtl_g_landtemperature, readpagedata(m,"test/validationdata/$valdir/rt_g_globaltemperature.csv"))
    set_param!(m, :PermafrostJULES, :rtl_g_landtemperature, readpagedata(m,"test/validationdata/$valdir/rt_g_globaltemperature.csv"))

    run(m)

    permco2 = m[:PermafrostTotal,  :perm_tot_c_co2]
    permco2_compare = readpagedata(m,"test/validationdata/$valdir/perm_tot_e_co2.csv")
    @test permco2 ≈ permco2_compare rtol=1e-4
    
    permch4 = m[:PermafrostTotal,  :perm_tot_ce_ch4]
    permch4_compare = readpagedata(m,"test/validationdata/$valdir/perm_tot_ce_ch4.csv")
    @test permch4 ≈ permch4_compare rtol=1e-4
end
