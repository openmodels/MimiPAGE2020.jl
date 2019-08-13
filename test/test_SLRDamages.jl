using DataFrames
using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/SLRDamages.jl")

    slrdamages = addslrdamages(m)

    set_param!(m, :SLRDamages, :y_year, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_param!(m, :SLRDamages, :atl_adjustedtolerablelevelofsealevelrise, readpagedata(m, "test/validationdata/atl_adjustedtolerablelevelofsealevelrise.csv"))
    set_param!(m, :SLRDamages, :imp_actualreductionSLR, readpagedata(m, "test/validationdata/$valdir/imp_actualreductionSLR.csv"))
    set_param!(m, :SLRDamages, :y_year_0, 2015.)
    set_param!(m, :SLRDamages, :s_sealevel, readpagedata(m, "test/validationdata/$valdir/s_sealevel.csv"))
    set_param!(m, :SLRDamages, :cons_percap_consumption, readpagedata(m, "test/validationdata/$valdir/cons_percap_consumption.csv"))
    set_param!(m, :SLRDamages, :tct_per_cap_totalcostspercap, readpagedata(m, "test/validationdata/$valdir/tct_per_cap_totalcostspercap.csv"))
    set_param!(m, :SLRDamages, :act_percap_adaptationcosts, readpagedata(m, "test/validationdata/$valdir/act_percap_adaptationcosts.csv"))
    set_param!(m, :SLRDamages, :isatg_impactfxnsaturation, 28.333333333333336)

    ##running Model
    run(m)

    cons_percap_aftercosts = m[:SLRDamages, :cons_percap_aftercosts]
    cons_percap_aftercosts_compare = readpagedata(m, "test/validationdata/$valdir/cons_percap_aftercosts.csv")
    @test ones(10, 8) ≈ cons_percap_aftercosts ./ cons_percap_aftercosts_compare rtol=.001

    i_regionalimpactSLR = m[:SLRDamages, :i_regionalimpactSLR]
    i_regionalimpactSLR_compare = readpagedata(m, "test/validationdata/$valdir/i_regionalimpact_SLRise.csv")
    @test i_regionalimpactSLR ≈ i_regionalimpactSLR_compare rtol=.001

    iref_ImpactatReferenceGDPperCapSLR = m[:SLRDamages, :iref_ImpactatReferenceGDPperCapSLR]
    iref_ImpactatReferenceGDPperCapSLR_compare = readpagedata(m, "test/validationdata/$valdir/iref_ImpactatReferenceGDPperCap_sea.csv")
    @test iref_ImpactatReferenceGDPperCapSLR ≈ iref_ImpactatReferenceGDPperCapSLR_compare rtol=.0001

    rcons_per_cap_SLRRemainConsumption = m[:SLRDamages, :rcons_per_cap_SLRRemainConsumption]
    rcons_per_cap_SLRRemainConsumption_compare = readpagedata(m, "test/validationdata/$valdir/rcons_per_cap_SLRRemainConsumption.csv")
    @test rcons_per_cap_SLRRemainConsumption ≈ rcons_per_cap_SLRRemainConsumption_compare rtol=.01

    rgdp_per_cap_SLRRemainGDP = m[:SLRDamages, :rgdp_per_cap_SLRRemainGDP]
    rgdp_per_cap_SLRRemainGDP_compare = readpagedata(m, "test/validationdata/$valdir/rgdp_per_cap_SLRRemainGDP.csv")
    @test rgdp_per_cap_SLRRemainGDP ≈ rgdp_per_cap_SLRRemainGDP_compare rtol=.01

    igdp_ImpactatActualGDPperCapSLR = m[:SLRDamages, :igdp_ImpactatActualGDPperCapSLR]
    igdp_ImpactatActualGDPperCapSLR_compare = readpagedata(m, "test/validationdata/$valdir/igdp_ImpactatActualGDPperCap_sea.csv")
    @test igdp_ImpactatActualGDPperCapSLR ≈ igdp_ImpactatActualGDPperCapSLR_compare rtol=.01

    isat_ImpactinclSaturationandAdaptationSLR = m[:SLRDamages, :isat_ImpactinclSaturationandAdaptationSLR]
    isat_ImpactinclSaturationandAdaptationSLR_compare = readpagedata(m, "test/validationdata/$valdir/isat_ImpactinclSaturationandAdaptation_SLRise.csv")
    @test isat_ImpactinclSaturationandAdaptationSLR ≈ isat_ImpactinclSaturationandAdaptationSLR_compare rtol=.001
end
