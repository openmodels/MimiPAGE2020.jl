using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    include("../src/main_model.jl")

    m = getpage(scenario, use_permafrost, use_seaice)
    run(m)

    if scenario == "NDCs"
        while m[:Discontinuity,:occurdis_occurrencedummy] != [0.,0.,0.,0.,0.,0.,1.,1.,1.,1.]
            println(m[:Discontinuity,:occurdis_occurrencedummy])
            run(m)
        end
    else
        while m[:Discontinuity,:occurdis_occurrencedummy] != [0.,0.,0.,0.,0.,0.,0.,0.,0.,0.]
            println(m[:Discontinuity,:occurdis_occurrencedummy])
            run(m)
        end
    end

    if updatetestdata
        include("../src/utils/save_parameters.jl")
        savepagedata(m, :Population, :pop_population, "test/validationdata/$valdir/pop_population.csv")
        savepagedata(m, :GDP, :cons_percap_consumption, "test/validationdata/$valdir/cons_percap_consumption.csv")
        savepagedata(m, :GDP, :gdp, "test/validationdata/$valdir/gdp.csv")
        savepagedata(m, :Discontinuity,:rcons_per_cap_DiscRemainConsumption, "test/validationdata/$valdir/rcons_per_cap_DiscRemainConsumption.csv")
        savepagedata(m, :TotalAbatementCosts, :tct_per_cap_totalcostspercap, "test/validationdata/$valdir/tct_per_cap_totalcostspercap.csv")
        savepagedata(m, :AdaptiveCostsEconomic, :ac_adaptivecosts, "test/validationdata/ac_adaptationcosts_economic.csv")
        savepagedata(m, :AdaptiveCostsNonEconomic, :ac_adaptivecosts, "test/validationdata/ac_adaptationcosts_noneconomic.csv")
        savepagedata(m, :AdaptiveCostsSeaLevel, :ac_adaptivecosts, "test/validationdata/$valdir/ac_adaptationcosts_sealevelrise.csv")
        savepagedata(m, :TotalAdaptationCosts, :act_adaptationcosts_total, "test/validationdata/$valdir/act_adaptationcosts_tot.csv")
        savepagedata(m, :TotalAdaptationCosts, :act_percap_adaptationcosts, "test/validationdata/$valdir/act_percap_adaptationcosts.csv")
        savepagedata(m, :SLRDamages,:rcons_per_cap_SLRRemainConsumption, "test/validationdata/$valdir/rcons_per_cap_SLRRemainConsumption.csv")
        savepagedata(m, :SLRDamages, :cons_percap_aftercosts, "test/validationdata/$valdir/cons_percap_aftercosts.csv")
        savepagedata(m, :MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption, "test/validationdata/$valdir/rcons_per_cap_MarketRemainConsumption.csv")
        savepagedata(m, :MarketDamagesBurke, :rgdp_per_cap_MarketRemainGDP, "test/validationdata/$valdir/rgdp_per_cap_MarketRemainGDP.csv")
        savepagedata(m, :NonMarketDamages, :rcons_per_cap_NonMarketRemainConsumption, "test/validationdata/$valdir/rcons_per_cap_NonMarketRemainConsumption.csv")
        savepagedata(m, :NonMarketDamages, :rgdp_per_cap_NonMarketRemainGDP, "test/validationdata/$valdir/rgdp_per_cap_NonMarketRemainGDP.csv")
        savepagedata(m, :SLRDamages, :rcons_per_cap_SLRRemainConsumption, "test/validationdata/$valdir/rcons_per_cap_SLRRemainConsumption.csv")
        savepagedata(m, :SLRDamages, :rgdp_per_cap_SLRRemainGDP, "test/validationdata/$valdir/rgdp_per_cap_SLRRemainGDP.csv")
        savepagedata(m, :SLRDamages, :igdp_ImpactatActualGDPperCapSLR, "test/validationdata/$valdir/igdp_ImpactatActualGDPperCap_sea.csv")
        savepagedata(m, :SLRDamages, :isat_ImpactinclSaturationandAdaptationSLR, "test/validationdata/$valdir/isat_ImpactinclSaturationandAdaptation_SLRise.csv")
        savepagedata(m, :EquityWeighting, :wtct_percap_weightedcosts, "test/validationdata/$valdir/wtct_percap_weightedcosts.csv")
        savepagedata(m, :EquityWeighting, :pct_percap_partiallyweighted, "test/validationdata/$valdir/pct_percap_partiallyweighted.csv")
        savepagedata(m, :EquityWeighting, :dr_discountrate, "test/validationdata/$valdir/dr_discountrate.csv")
        savepagedata(m, :EquityWeighting, :dfc_consumptiondiscountrate, "test/validationdata/$valdir/dfc_consumptiondiscountrate.csv")
        savepagedata(m, :EquityWeighting, :pct_partiallyweighted, "test/validationdata/$valdir/pct_partiallyweighted.csv")
        savepagedata(m, :EquityWeighting, :pcdt_partiallyweighted_discounted, "test/validationdata/$valdir/pcdt_partiallyweighted_discounted.csv")
        savepagedata(m, :EquityWeighting, :wacdt_partiallyweighted_discounted, "test/validationdata/$valdir/wacdt_partiallyweighted_discounted.csv")
        savepagedata(m, :EquityWeighting, :aact_equityweightedadaptation_discountedaggregated, "test/validationdata/$valdir/aact_equityweightedadaptation_discountedaggregated.csv")
        savepagedata(m, :EquityWeighting, :wit_equityweightedimpact, "test/validationdata/$valdir/wit_equityweightedimpact.csv")
        savepagedata(m, :EquityWeighting, :addt_equityweightedimpact_discountedaggregated, "test/validationdata/$valdir/addt_equityweightedimpact_discountedaggregated.csv")
    end

    #climate component
    temp=m[:ClimateTemperature,:rt_g_globaltemperature]
    temp_compare=readpagedata(m,"test/validationdata/$valdir/rt_g_globaltemperature.csv")
    @test temp ≈ temp_compare rtol=1e-3

    slr=m[:SeaLevelRise,:s_sealevel]
    slr_compare=readpagedata(m,"test/validationdata/$valdir/s_sealevel.csv")
    @test slr ≈ slr_compare rtol=1e-2

    #Socio-Economics
    gdp=m[:GDP,:gdp]
    gdp_compare=readpagedata(m,"test/validationdata/$valdir/gdp.csv")
    @test gdp ≈ gdp_compare rtol=1

    pop=m[:Population,:pop_population]
    pop_compare=readpagedata(m,"test/validationdata/$valdir/pop_population.csv")
    @test pop ≈ pop_compare rtol=0.001

    #Abatement Costs
    abatement=m[:TotalAbatementCosts,:tct_totalcosts]
    abatement_compare=readpagedata(m,"test/validationdata/$valdir/tct_totalcosts.csv")
    @test abatement ≈ abatement_compare rtol=1e-2

    #Adaptation Costs
    adaptation=m[:TotalAdaptationCosts,:act_adaptationcosts_total]
    adaptation_compare=readpagedata(m, "test/validationdata/$valdir/act_adaptationcosts_tot.csv")
    @test adaptation ≈ adaptation_compare rtol=1e-2

    #Damages
    damages=m[:Discontinuity,:rcons_per_cap_DiscRemainConsumption]
    damages_compare=readpagedata(m,"test/validationdata/$valdir/rcons_per_cap_DiscRemainConsumption.csv")
    @test damages ≈ damages_compare rtol=10
    #SLR damages
    slrdamages=m[:SLRDamages,:rcons_per_cap_SLRRemainConsumption]
    slrdamages_compare=readpagedata(m, "test/validationdata/$valdir/rcons_per_cap_SLRRemainConsumption.csv")
    @test slrdamages ≈ slrdamages_compare rtol=0.1
    #Market damages
    mdamages=m[:MarketDamages,:rcons_per_cap_MarketRemainConsumption]
    mdamages_compare=readpagedata(m,"test/validationdata/$valdir/rcons_per_cap_MarketRemainConsumption.csv")
    @test mdamages ≈ mdamages_compare rtol=1
    #NonMarket Damages
    nmdamages=m[:NonMarketDamages,:rcons_per_cap_NonMarketRemainConsumption]
    nmdamages_compare=readpagedata(m,"test/validationdata/$valdir/rcons_per_cap_NonMarketRemainConsumption.csv")
    @test nmdamages ≈ nmdamages_compare rtol=1

    te = m[:EquityWeighting, :te_totaleffect]
    if scenario == "NDCs"
        te_compare = 1.0320923880568126e9
    elseif scenario == "2 degC Target"
        te_compare = 5.0496576104580307e8
    end
    @test te ≈ te_compare rtol=1e4
end
