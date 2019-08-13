using DataFrames
using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/NonMarketDamages.jl")

    nonmarketdamages = addnonmarketdamages(m)

    set_param!(m, :NonMarketDamages, :rtl_realizedtemperature, readpagedata(m, "test/validationdata/$valdir/rtl_realizedtemperature.csv"))
    set_param!(m, :NonMarketDamages, :rcons_per_cap_MarketRemainConsumption, readpagedata(m, "test/validationdata/$valdir/rcons_per_cap_MarketRemainConsumption.csv"))
    set_param!(m, :NonMarketDamages, :rgdp_per_cap_MarketRemainGDP, readpagedata(m, "test/validationdata/$valdir/rgdp_per_cap_MarketRemainGDP.csv"))
    set_param!(m, :NonMarketDamages, :atl_adjustedtolerableleveloftemprise, readpagedata(m, "test/validationdata/atl_adjustedtolerableleveloftemprise_nonmarket.csv"))
    set_param!(m, :NonMarketDamages, :imp_actualreduction, readpagedata(m, "test/validationdata/$valdir/imp_actualreduction_nonmarket.csv"))
    set_param!(m, :NonMarketDamages, :isatg_impactfxnsaturation, 17.0)

    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)
    rcons_per_cap = m[:NonMarketDamages, :rcons_per_cap_NonMarketRemainConsumption]
    rcons_per_cap_compare = readpagedata(m, "test/validationdata/$valdir/rcons_per_cap_NonMarketRemainConsumption.csv")
    @test rcons_per_cap ≈ rcons_per_cap_compare rtol=1e-2

    rgdp_per_cap = m[:NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP]
    rgdp_per_cap_compare = readpagedata(m, "test/validationdata/$valdir/rgdp_per_cap_NonMarketRemainGDP.csv")
    @test rgdp_per_cap ≈ rgdp_per_cap_compare rtol=1e-2
end
