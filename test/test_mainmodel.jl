using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    Mimi.reset_compdefs()

    include("../src/getpagefunction.jl")

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
