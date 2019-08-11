using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/MarketDamagesBurke.jl")

    marketdamages = addmarketdamagesburke(m)

    set_param!(m, :MarketDamagesBurke, :rtl_realizedtemperature, readpagedata(m, "test/validationdata/$valdir/rtl_realizedtemperature.csv"))
    set_param!(m, :MarketDamagesBurke, :rcons_per_cap_SLRRemainConsumption, readpagedata(m,"test/validationdata/$valdir/rcons_per_cap_SLRRemainConsumption.csv"))
    set_param!(m, :MarketDamagesBurke, :rgdp_per_cap_SLRRemainGDP, readpagedata(m,"test/validationdata/$valdir/rgdp_per_cap_SLRRemainGDP.csv"))
    set_param!(m, :MarketDamagesBurke, :isatg_impactfxnsaturation, 28.333333333333336)

    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)

    rcons_per_cap = m[:MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption]
    rcons_per_cap_compare = readpagedata(m, "test/validationdata/$valdir/rcons_per_cap_MarketRemainConsumption.csv")
    @test rcons_per_cap ≈ rcons_per_cap_compare rtol=1e-1

    rgdp_per_cap = m[:MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP]
    rgdp_per_cap_compare = readpagedata(m, "test/validationdata/$valdir/rgdp_per_cap_MarketRemainGDP.csv")
    @test rgdp_per_cap ≈ rgdp_per_cap_compare rtol=1e-2
end
