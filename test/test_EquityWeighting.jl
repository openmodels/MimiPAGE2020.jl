using Test

for testscen in 1:2
    if testscen == 2
        continue # this validation data is missing
    end

    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/RCPSSPScenario.jl")
    include("../src/components/EquityWeighting.jl")

    rcpsspscenario = addrcpsspscenario(m, scenario)
    equityweighting = add_comp!(m, EquityWeighting)

    equityweighting[:tct_percap_totalcosts_total] = readpagedata(m, "test/validationdata/$valdir/tct_per_cap_totalcostspercap.csv")
    equityweighting[:act_adaptationcosts_total] = readpagedata(m, "test/validationdata/$valdir/act_adaptationcosts_tot.csv")
    equityweighting[:act_percap_adaptationcosts] = readpagedata(m, "test/validationdata/$valdir/act_percap_adaptationcosts.csv")
    equityweighting[:cons_percap_aftercosts] = readpagedata(m, "test/validationdata/$valdir/cons_percap_aftercosts.csv")
    equityweighting[:cons_percap_consumption] = readpagedata(m, "test/validationdata/$valdir/cons_percap_consumption.csv")
    equityweighting[:cons_percap_consumption_0] = readpagedata(m, "test/validationdata/cons_percap_consumption_0.csv")
    equityweighting[:rcons_percap_dis] = readpagedata(m, "test/validationdata/$valdir/rcons_per_cap_DiscRemainConsumption.csv")
    equityweighting[:yagg_periodspan] = readpagedata(m, "test/validationdata/yagg_periodspan.csv")
    equityweighting[:pop_population] = readpagedata(m, "test/validationdata/$valdir/pop_population.csv")
    equityweighting[:y_year_0] = 2015.
    equityweighting[:y_year] = Mimi.dim_keys(m.md, :time)
    equityweighting[:grw_gdpgrowthrate] = rcpsspscenario[:grw_gdpgrowthrate]
    equityweighting[:popgrw_populationgrowth] = rcpsspscenario[:popgrw_populationgrowth]

    p = load_parameters(m)
    set_leftover_params!(m, p)

    run(m)

    # Generated data
    df = m[:EquityWeighting, :df_utilitydiscountfactor]
    wtct_percap = m[:EquityWeighting, :wtct_percap_weightedcosts]
    pct_percap = m[:EquityWeighting, :pct_percap_partiallyweighted]
    dr = m[:EquityWeighting, :dr_discountrate]
    dfc = m[:EquityWeighting, :dfc_consumptiondiscountrate]
    pct = m[:EquityWeighting, :pct_partiallyweighted]
    pcdt = m[:EquityWeighting, :pcdt_partiallyweighted_discounted]
    wacdt = m[:EquityWeighting, :wacdt_partiallyweighted_discounted]
    aact = m[:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated]

    wit = m[:EquityWeighting, :wit_equityweightedimpact]
    addt = m[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]
    addt_gt = m[:EquityWeighting, :addt_gt_equityweightedimpact_discountedglobal]
    te = m[:EquityWeighting, :te_totaleffect]

    # Recorded data
    df_compare = readpagedata(m, "test/validationdata/df_utilitydiscountfactor.csv")
    wtct_percap_compare = readpagedata(m, "test/validationdata/$valdir/wtct_percap_weightedcosts.csv")
    pct_percap_compare = readpagedata(m, "test/validationdata/$valdir/pct_percap_partiallyweighted.csv")
    dr_compare = readpagedata(m, "test/validationdata/$valdir/dr_discountrate.csv")
    dfc_compare = readpagedata(m, "test/validationdata/$valdir/dfc_consumptiondiscountrate.csv")
    pct_compare = readpagedata(m, "test/validationdata/$valdir/pct_partiallyweighted.csv")
    pcdt_compare = readpagedata(m, "test/validationdata/$valdir/pcdt_partiallyweighted_discounted.csv")
    wacdt_compare = readpagedata(m, "test/validationdata/$valdir/wacdt_partiallyweighted_discounted.csv")
    aact_compare = readpagedata(m, "test/validationdata/$valdir/aact_equityweightedadaptation_discountedaggregated.csv")

    wit_compare = readpagedata(m, "test/validationdata/$valdir/wit_equityweightedimpact.csv")
    addt_compare = readpagedata(m, "test/validationdata/$valdir/addt_equityweightedimpact_discountedaggregated.csv")
    addt_gt_compare = (scenario == "NDCs" ? 9.960706559386551e8 : 3.445096140740376e8)
    te_compare = (scenario == "NDCs" ? 1.0320923880568126e9 : 5.0496576104580307e8)

    @test df ≈ df_compare rtol=1e-8
    @test wtct_percap ≈ wtct_percap_compare rtol=1e-7
    @test pct_percap ≈ pct_percap_compare rtol=1e-7
    @test dr ≈ dr_compare rtol=1e-5
    @test dfc ≈ dfc_compare rtol=1e-7
    @test pct ≈ pct_compare rtol=1e-3
    @test pcdt ≈ pcdt_compare rtol=1e-3
    @test wacdt ≈ wacdt_compare rtol=1e-4

    @test aact ≈ aact_compare rtol=1e-3

    @test wit ≈ wit_compare rtol=1e-3
    @test addt ≈ addt_compare rtol=1e-2
    @test addt_gt ≈ addt_gt_compare rtol=1e-2

    @test te ≈ te_compare rtol=1e-2
end
