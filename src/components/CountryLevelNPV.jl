@defcomp CountryLevelNPV begin
    country = Index()

    # Basic information
    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")

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
    wact_partiallyweighted = Variable(index=[time, country], unit="\$million")

    pct_partiallyweighted = Variable(index=[time, country], unit="\$million")

    # Discount rates
    ptp_timepreference = Variable(unit="%/year")
    grw_gdpgrowthrate = Parameter(index=[time, country], unit="%/year")
    popgrw_populationgrowth = Parameter(index=[time, country], unit="%/year")

    dr_discountrate = Variable(index=[time, country], unit="%/year")
    yp_yearsperiod = Variable(index=[time], unit="year") # defined differently from yagg
    dfc_consumptiondiscountrate = Variable(index=[time, country], unit="1/year")

    df_utilitydiscountfactor = Variable(index=[time], unit="fraction")

    discfix_fixediscountrate = Parameter(unit="none", default=0.) # override the discount rates with something exogenous

    # Discounted costs
    pcdt_partiallyweighted_discounted = Variable(index=[time, country], unit="\$million")

    pcdat_partiallyweighted_discountedaggregated = Variable(index=[time, country], unit="\$million")
    wacdt_partiallyweighted_discounted = Variable(index=[time, country], unit="\$million")

    # NPV impact totals
    rcons_percap_dis = Parameter(index=[time, country], unit="\$/person")

    wit_equityweightedimpact = Variable(index=[time, country], unit="\$million")
    wit_percap_equityweightedimpact = Variable(index=[time, country], unit="\$million")
    widt_equityweightedimpact_discounted = Variable(index=[time, country], unit="\$million")

    yagg_periodspan = Parameter(index=[time], unit="year")

    addt_equityweightedimpact_discountedaggregated = Variable(index=[time, country], unit="\$million")
    aact_equityweightedadaptation_discountedaggregated = Variable(index=[time, country], unit="\$million")

    td_totaldiscountedimpacts = Variable(index=[country], unit="\$million")

    function init(pp, vv, dd)
        if pp.pref_draw == -1
            vv.ptp_timepreference = 1.0333333333333334
            vv.emuc_utilityconvexity = 1.1666666666666667
        else
            prefs = CSV.read("../data/preferences/druppetal2018.csv", DataFrame)
            vv.ptp_timepreference = prefs.puretp[pp.pref_draw]
            vv.emuc_utilityconvexity = prefs.eta[pp.pref_draw]
        end
    end

    function run_timestep(p, v, d, tt)
        if is_first(tt)
            v.td_totaldiscountedimpacts[:] .= 0
        end

        if p.discfix_fixediscountrate != 0.
            v.df_utilitydiscountfactor[tt] = (1 + p.discfix_fixediscountrate / 100)^(-(p.y_year[tt] - p.y_year_0))
        else
            v.df_utilitydiscountfactor[tt] = (1 + v.ptp_timepreference / 100)^(-(p.y_year[tt] - p.y_year_0))
        end

        for cc in d.country

            ## Gas Costs Accounting
            # Weighted costs (Page 23 of Hope 2009)
            v.wtct_percap_weightedcosts[tt, cc] = ((p.cons_percap_consumption_0[cc]^v.emuc_utilityconvexity) / (1 - v.emuc_utilityconvexity)) * (p.cons_percap_consumption[tt, cc]^(1 - v.emuc_utilityconvexity) - (p.cons_percap_consumption[tt, cc] - p.tct_percap_totalcosts_total[tt, cc] < 0.01 * p.cons_percap_consumption_0[cc] ? 0.01 * p.cons_percap_consumption_0[cc] : p.cons_percap_consumption[tt, cc] - p.tct_percap_totalcosts_total[tt, cc])^(1 - v.emuc_utilityconvexity))

            # Add these into consumption
            v.eact_percap_weightedadaptationcosts[tt, cc] = ((p.cons_percap_consumption_0[cc]^v.emuc_utilityconvexity) / (1 - v.emuc_utilityconvexity)) * (p.cons_percap_consumption[tt, cc]^(1 - v.emuc_utilityconvexity) - (p.cons_percap_consumption[tt, cc] - p.act_percap_adaptationcosts[tt, cc] < 0.01 * p.cons_percap_consumption_0[cc] ? 0.01 * p.cons_percap_consumption_0[cc] : p.cons_percap_consumption[tt, cc] - p.act_percap_adaptationcosts[tt, cc])^(1 - v.emuc_utilityconvexity))

            v.pct_partiallyweighted[tt, cc] = p.tct_percap_totalcosts_total[tt, cc] * p.pop_population[tt, cc]
            v.wact_partiallyweighted[tt, cc] = p.act_percap_adaptationcosts[tt, cc] * p.pop_population[tt, cc]

            if p.discfix_fixediscountrate != 0.
                v.dr_discountrate[tt, cc] = p.discfix_fixediscountrate
            else
                v.dr_discountrate[tt, cc] = v.ptp_timepreference + v.emuc_utilityconvexity * (p.grw_gdpgrowthrate[tt, cc] - p.popgrw_populationgrowth[tt, cc])
            end

            if is_first(tt)
                v.yp_yearsperiod[TimestepIndex(1)] = p.y_year[TimestepIndex(1)] - p.y_year_0
            else
                v.yp_yearsperiod[tt] = p.y_year[tt] - p.y_year[tt - 1]
            end

            if is_first(tt)
                v.dfc_consumptiondiscountrate[TimestepIndex(1), cc] = (1 + v.dr_discountrate[TimestepIndex(1), cc] / 100)^(-v.yp_yearsperiod[TimestepIndex(1)])
            else
                v.dfc_consumptiondiscountrate[tt, cc] = v.dfc_consumptiondiscountrate[tt - 1, cc] * (1 + v.dr_discountrate[tt, cc] / 100)^(-v.yp_yearsperiod[tt])
            end

            # Discounted costs
            v.pcdt_partiallyweighted_discounted[tt, cc] = v.pct_partiallyweighted[tt, cc] * v.dfc_consumptiondiscountrate[tt, cc]
            v.wacdt_partiallyweighted_discounted[tt, cc] = v.wact_partiallyweighted[tt, cc] * v.dfc_consumptiondiscountrate[tt, cc]

            v.wit_percap_equityweightedimpact[tt, cc] = (p.cons_percap_aftercosts[tt, cc] - p.rcons_percap_dis[tt, cc]) # equivalent to emuc = 0
            v.wit_equityweightedimpact[tt, cc] = v.wit_percap_equityweightedimpact[tt, cc] * p.pop_population[tt, cc]
            v.widt_equityweightedimpact_discounted[tt, cc] = v.wit_equityweightedimpact[tt, cc] * v.dfc_consumptiondiscountrate[tt] # apply Ramsey discounting

            v.pcdat_partiallyweighted_discountedaggregated[tt, cc] = v.pcdt_partiallyweighted_discounted[tt, cc] * p.yagg_periodspan[tt]

            v.addt_equityweightedimpact_discountedaggregated[tt, cc] = v.widt_equityweightedimpact_discounted[tt, cc] * p.yagg_periodspan[tt]
            v.aact_equityweightedadaptation_discountedaggregated[tt, cc] = v.wacdt_partiallyweighted_discounted[tt, cc] * p.yagg_periodspan[tt]

            v.td_totaldiscountedimpacts[cc] = v.td_totaldiscountedimpacts[cc] + v.addt_equityweightedimpact_discountedaggregated[tt, cc]
        end
    end
end

function addcountrylevelnpv(model::Model)
    countrylevel = add_comp!(model, CountryLevelNPV)
    countrylevel[:model] = model
    countrylevel[:pref_draw] = -1
    countrylevel
end
