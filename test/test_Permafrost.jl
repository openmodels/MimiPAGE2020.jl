include("../src/components/PermafrostSiBCASA.jl")
include("../src/components/PermafrostJULES.jl")
include("../src/components/PermafrostTotal.jl")

using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()

    permafrost_sibcasa = add_comp!(m, PermafrostSiBCASA)
    permafrost_jules = add_comp!(m, PermafrostJULES)
    permafrost_total = add_comp!(m, PermafrostTotal)

    permafrost_total[:perm_sib_ce_co2] = permafrost_sibcasa[:perm_sib_ce_co2]
    permafrost_total[:perm_sib_e_co2] = permafrost_sibcasa[:perm_sib_e_co2]
    permafrost_total[:perm_sib_ce_ch4] = permafrost_sibcasa[:perm_sib_ce_ch4]
    permafrost_total[:perm_jul_ce_co2] = permafrost_jules[:perm_jul_ce_co2]
    permafrost_total[:perm_jul_e_co2] = permafrost_jules[:perm_jul_e_co2]
    permafrost_total[:perm_jul_ce_ch4] = permafrost_jules[:perm_jul_ce_ch4]

    set_param!(m, :PermafrostSiBCASA, :rt_g, readpagedata(m,"test/validationdata/$valdir/rt_g_globaltemperature.csv"))
    set_param!(m, :PermafrostJULES, :rt_g, readpagedata(m,"test/validationdata/$valdir/rt_g_globaltemperature.csv"))

    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)

    permjcco2 = m[:PermafrostJULES,  :perm_jul_ce_c_co2]
    permjcco2_compare = readpagedata(m,"test/validationdata/$valdir/perm_jul_ce_c_co2.csv")
    @test permjcco2 ≈ permjcco2_compare rtol=1e-4

    permsco2 = m[:PermafrostSiBCASA,  :perm_sib_ce_co2]
    permsco2_compare = readpagedata(m,"test/validationdata/$valdir/perm_sib_ce_co2.csv")
    @test permsco2 ≈ permsco2_compare rtol=1e-4

    permco2 = m[:PermafrostTotal,  :perm_tot_e_co2]
    permco2_compare = readpagedata(m,"test/validationdata/$valdir/perm_tot_e_co2.csv")
    @test permco2 ≈ permco2_compare rtol=1e-4

    permch4 = m[:PermafrostTotal,  :perm_tot_ce_ch4]
    permch4_compare = readpagedata(m,"test/validationdata/$valdir/perm_tot_ce_ch4.csv")
    @test permch4 ≈ permch4_compare rtol=1e-4
end
