using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/MarketDamages.jl")

    marketdamages = addmarketdamages(m)

    set_param!(m, :MarketDamages, :rtl_realizedtemperature, readpagedata(m, "test/validationdata/$valdir/rtl_realizedtemperature.csv"))
    set_param!(m, :MarketDamages, :rcons_per_cap_SLRRemainConsumption, readpagedata(m,"test/validationdata/$valdir/rcons_per_cap_SLRRemainConsumption.csv"))
    set_param!(m, :MarketDamages, :rgdp_per_cap_SLRRemainGDP, readpagedata(m,"test/validationdata/$valdir/rgdp_per_cap_SLRRemainGDP.csv"))
    set_param!(m, :MarketDamages, :atl_adjustedtolerableleveloftemprise, readpagedata(m,"test/validationdata/atl_adjustedtolerableleveloftemprise_market.csv"))
    set_param!(m, :MarketDamages, :imp_actualreduction, readpagedata(m,"test/validationdata/$valdir/imp_actualreduction_market.csv"))
    set_param!(m, :MarketDamages, :isatg_impactfxnsaturation, 28.333333333333336)

    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)

    ## Not a very good test, but damages are based on Burke et al. now anyway
    iref = m[:MarketDamages, :iref_ImpactatReferenceGDPperCap]
    iref_compare = readpagedata(m, "test/validationdata/$valdir/iref_ImpactatReferenceGDPperCap_econ_page.csv")
    @test iref ≈ iref_compare rtol=1e-1

    # rcons_per_cap = m[:MarketDamages, :rcons_per_cap_MarketRemainConsumption]
    # rcons_per_cap_compare = readpagedata(m, "test/validationdata/rcons_per_cap_MarketRemainConsumption.csv")
    # @test rcons_per_cap ≈ rcons_per_cap_compare rtol=1e-1

    # rgdp_per_cap = m[:MarketDamages, :rgdp_per_cap_MarketRemainGDP]
    # rgdp_per_cap_compare = readpagedata(m, "test/validationdata/rgdp_per_cap_MarketRemainGDP.csv")
    # @test rgdp_per_cap ≈ rgdp_per_cap_compare rtol=1e-2
end
