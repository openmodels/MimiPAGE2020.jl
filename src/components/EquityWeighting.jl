include("../utils/welfare.jl")

@defcomp EquityWeighting begin
    country = Index()

    # Basic information
    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")
    cc_focus = Variable{Int64}() # Median country chosen on init

    # Impacts across all gases
    pop_population = Parameter(index=[time, country], unit="million person")

    # Total and Per-Capita Abatement and Adaptation Costs
    tct_percap_totalcosts_total = Parameter(index=[time, country], unit="\$/person")
    act_percap_adaptationcosts = Parameter(index=[time, country], unit="\$/person")

    # Consumption
    cons_percap_consumption = Parameter(index=[time, country], unit="\$/person") # Called "CONS_PER_CAP"
    cons_percap_consumption_0 = Parameter(index=[country], unit="\$/person")
    cons_percap_aftercosts = Parameter(index=[time, country], unit="\$/person")

    # Calculation of weighted costs
    pref_draw = Parameter{Int64}()
    emuc_utilityconvexity = Variable(unit="none")

    wtct_percap_weightedcosts = Variable(index=[time, country], unit="\$/person")
    eact_percap_weightedadaptationcosts = Variable(index=[time, country], unit="\$/person")
    wact_percap_partiallyweighted = Variable(index=[time, country], unit="\$/person")
    wact_partiallyweighted = Variable(index=[time, country], unit="\$million")

    # Amount of equity weighting variable (0, (0, 1), or 1)
    equity_proportion = Parameter(unit="fraction", default=1.0)

    pct_percap_partiallyweighted = Variable(index=[time, country], unit="\$/person")
    pct_partiallyweighted = Variable(index=[time, country], unit="\$million")
    pct_g_partiallyweighted_global = Variable(index=[time], unit="\$million")

    # Discount rates
    ptp_timepreference = Variable(unit="%/year")
    grw_gdpgrowthrate = Parameter(index=[time, country], unit="%/year")
    popgrw_populationgrowth = Parameter(index=[time, country], unit="%/year")

    df_utilitydiscountfactor = Variable(index=[time], unit="fraction")
    dfc_consumptiondiscountrate = Variable(index=[time, country], unit="1/year")

    discfix_fixediscountrate = Parameter(unit="none", default=0.) # override the discount rates with something exogenous

    # Discounted costs
    pcdt_partiallyweighted_discounted = Variable(index=[time, country], unit="\$million")
    pcdt_g_partiallyweighted_discountedglobal = Variable(index=[time], unit="\$million")

    pcdat_partiallyweighted_discountedaggregated = Variable(index=[time, country], unit="\$million")
    tpc_totalaggregatedcosts = Variable(unit="\$million")

    wacdt_partiallyweighted_discounted = Variable(index=[time, country], unit="\$million")

    # Equity weighted impact totals
    rcons_percap_dis = Parameter(index=[time, country], unit="\$/person")

    wit_equityweightedimpact = Variable(index=[time, country], unit="\$million")
    wit_percap_equityweightedimpact = Variable(index=[time, country], unit="\$million")
    widt_equityweightedimpact_discounted = Variable(index=[time, country], unit="\$million")

    yagg_periodspan = Parameter(index=[time], unit="year")

    addt_equityweightedimpact_discountedaggregated = Variable(index=[time, country], unit="\$million")
    addt_gt_equityweightedimpact_discountedglobal = Variable(unit="\$million")

    civvalue_civilizationvalue = Parameter(unit="\$million", default=6.1333333333333336e10) # Called "CIV_VALUE"
    td_totaldiscountedimpacts = Variable(unit="\$million")

    aact_equityweightedadaptation_discountedaggregated = Variable(index=[time, country], unit="\$million")
    tac_totaladaptationcosts = Variable(unit="\$million")

    # SCC comparison variables
    tdac_totalimpactandadaptation = Variable(unit="\$million")

    # Final result: total effect of climate change
    te_totaleffect = Variable(unit="\$million")

    function init(pp, vv, dd)
        if pp.pref_draw == -1
            vv.ptp_timepreference = 0.5
            vv.emuc_utilityconvexity = 1.01 # equations need to be rederived for emuc = 1
        else
            prefs = CSV.read("../data/preferences/druppetal2018.csv", DataFrame)
            vv.ptp_timepreference = prefs.puretp[pp.pref_draw]
            vv.emuc_utilityconvexity = prefs.eta[pp.pref_draw]
            if vv.emuc_utilityconvexity == 1.0
                vv.emuc_utilityconvexity += (rand() - 0.5) / 5 # -.1 to .1
            end
        end

        vv.cc_focus = argmin(abs.(pp.cons_percap_consumption_0 .- median(pp.cons_percap_consumption_0)))
    end

    function run_timestep(p, v, d, tt)
        if is_first(tt)
            v.tpc_totalaggregatedcosts = 0
            v.addt_gt_equityweightedimpact_discountedglobal = 0
            v.tac_totaladaptationcosts = 0
            v.te_totaleffect = 0

        end

        if p.discfix_fixediscountrate != 0.
            v.df_utilitydiscountfactor[tt] = df_utilitydiscountfactor(p.discfix_fixediscountrate, p.y_year[tt], p.y_year_0)
        else
            v.df_utilitydiscountfactor[tt] = df_utilitydiscountfactor(v.ptp_timepreference, p.y_year[tt], p.y_year_0)
        end

        for cc in d.country

            ## Gas Costs Accounting
            v.wtct_percap_weightedcosts[tt, cc] = weighted_costs(p.cons_percap_consumption_0[v.cc_focus], v.emuc_utilityconvexity, cc, p.cons_percap_consumption[tt, cc], p.tct_percap_totalcosts_total[tt, cc])
            v.eact_percap_weightedadaptationcosts[tt, cc] = weighted_costs(p.cons_percap_consumption_0[v.cc_focus], v.emuc_utilityconvexity, cc, p.cons_percap_consumption[tt, cc], p.act_percap_adaptationcosts[tt, cc])

            # Do partial weighting
            if p.equity_proportion == 0
                v.pct_percap_partiallyweighted[tt, cc] = p.tct_percap_totalcosts_total[tt, cc]
                v.wact_percap_partiallyweighted[tt, cc] = p.act_percap_adaptationcosts[tt, cc]
            else
                v.pct_percap_partiallyweighted[tt, cc] = (1 - p.equity_proportion) * p.tct_percap_totalcosts_total[tt, cc] + p.equity_proportion * v.wtct_percap_weightedcosts[tt, cc]
                v.wact_percap_partiallyweighted[tt, cc] = (1 - p.equity_proportion) * p.act_percap_adaptationcosts[tt, cc] + p.equity_proportion * v.eact_percap_weightedadaptationcosts[tt, cc]
            end

            v.pct_partiallyweighted[tt, cc] = v.pct_percap_partiallyweighted[tt, cc] * p.pop_population[tt, cc]
            v.wact_partiallyweighted[tt, cc] = v.wact_percap_partiallyweighted[tt, cc] * p.pop_population[tt, cc]

            if p.discfix_fixediscountrate != 0.
                dr_discountrate = p.discfix_fixediscountrate
            else
                dr_discountrate = v.ptp_timepreference + v.emuc_utilityconvexity * (p.grw_gdpgrowthrate[tt, cc] - p.popgrw_populationgrowth[tt, cc])
            end

            if is_first(tt)
                yp_yearsperiod = p.y_year[tt] - p.y_year_0
                v.dfc_consumptiondiscountrate[tt, cc] = (1 + dr_discountrate / 100)^(-yp_yearsperiod)
            else
                yp_yearsperiod = p.y_year[tt] - p.y_year[tt - 1]
                v.dfc_consumptiondiscountrate[tt, cc] = v.dfc_consumptiondiscountrate[tt - 1, cc] * (1 + dr_discountrate / 100)^(-yp_yearsperiod)
            end

            # Discounted costs
            if p.equity_proportion == 0
                v.pcdt_partiallyweighted_discounted[tt, cc] = v.pct_partiallyweighted[tt, cc] * v.dfc_consumptiondiscountrate[tt, cc]
                v.wacdt_partiallyweighted_discounted[tt, cc] = p.wact_partiallyweighted[tt, cc] * v.dfc_consumptiondiscountrate[tt, cc]

                v.wit_percap_equityweightedimpact[tt, cc] = (p.cons_percap_aftercosts[tt, cc] - p.rcons_percap_dis[tt, cc]) # equivalent to emuc = 0
                v.wit_equityweightedimpact[tt, cc] = v.wit_percap_equityweightedimpact[tt, cc] * p.pop_population[tt, cc]
                v.widt_equityweightedimpact_discounted[tt, cc] = v.wit_equityweightedimpact[tt, cc] * v.dfc_consumptiondiscountrate[tt] # apply Ramsey discounting
            else
                v.pcdt_partiallyweighted_discounted[tt, cc] = v.pct_partiallyweighted[tt, cc] * v.df_utilitydiscountfactor[tt]
                v.wacdt_partiallyweighted_discounted[tt, cc] = v.wact_partiallyweighted[tt, cc] * v.df_utilitydiscountfactor[tt]

                ## Equity weighted impacts (end of page 28, Hope 2009)
                v.wit_percap_equityweightedimpact[tt, cc] = ((p.cons_percap_consumption_0[v.cc_focus]^v.emuc_utilityconvexity) / (1 - v.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, cc]^(1 - v.emuc_utilityconvexity) - p.rcons_percap_dis[tt, cc]^(1 - v.emuc_utilityconvexity))
                v.wit_equityweightedimpact[tt, cc] = v.wit_percap_equityweightedimpact[tt, cc] * p.pop_population[tt, cc]
                v.widt_equityweightedimpact_discounted[tt, cc] = v.wit_equityweightedimpact[tt, cc] * v.df_utilitydiscountfactor[tt]
            end

            v.pcdat_partiallyweighted_discountedaggregated[tt, cc] = v.pcdt_partiallyweighted_discounted[tt, cc] * p.yagg_periodspan[tt]

            v.addt_equityweightedimpact_discountedaggregated[tt, cc] = v.widt_equityweightedimpact_discounted[tt, cc] * p.yagg_periodspan[tt]
            v.aact_equityweightedadaptation_discountedaggregated[tt, cc] = v.wacdt_partiallyweighted_discounted[tt, cc] * p.yagg_periodspan[tt]
        end

        v.pct_g_partiallyweighted_global[tt] = sum(v.pct_partiallyweighted[tt, :])
        v.pcdt_g_partiallyweighted_discountedglobal[tt] = sum(v.pcdt_partiallyweighted_discounted[tt, :])
        v.tpc_totalaggregatedcosts = v.tpc_totalaggregatedcosts + sum(v.pcdat_partiallyweighted_discountedaggregated[tt, :])

        v.addt_gt_equityweightedimpact_discountedglobal = v.addt_gt_equityweightedimpact_discountedglobal + sum(v.addt_equityweightedimpact_discountedaggregated[tt, :])

        v.tac_totaladaptationcosts = v.tac_totaladaptationcosts + sum(v.aact_equityweightedadaptation_discountedaggregated[tt, :])

        v.td_totaldiscountedimpacts = min(v.addt_gt_equityweightedimpact_discountedglobal, p.civvalue_civilizationvalue)

        # New results for SCC comparison
        v.tdac_totalimpactandadaptation = min(v.td_totaldiscountedimpacts + v.tac_totaladaptationcosts, p.civvalue_civilizationvalue)

        # Total effect of climate change
        v.te_totaleffect = min(v.td_totaldiscountedimpacts + v.tpc_totalaggregatedcosts + v.tac_totaladaptationcosts, p.civvalue_civilizationvalue)
    end
end

function addequityweighting(model::Model)
    equityweighting = add_comp!(model, EquityWeighting)
    equityweighting[:model] = model
    equityweighting[:pref_draw] = -1
    equityweighting
end
