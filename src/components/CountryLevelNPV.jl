include("../utils/welfare.jl")

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

    wact_partiallyweighted = Variable(index=[time, country], unit="\$million")

    pct_partiallyweighted = Variable(index=[time, country], unit="\$million")

    # Discount rates
    ptp_timepreference = Variable(unit="%/year")
    grw_gdpgrowthrate = Parameter(index=[time, country], unit="%/year")
    popgrw_populationgrowth = Parameter(index=[time, country], unit="%/year")

    dfc_consumptiondiscountrate = Variable(index=[time, country], unit="1/year")

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
            vv.ptp_timepreference = 0.5
            vv.emuc_utilityconvexity = 1.
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

        for cc in d.country
            v.pct_partiallyweighted[tt, cc] = p.tct_percap_totalcosts_total[tt, cc] * p.pop_population[tt, cc]
            v.wact_partiallyweighted[tt, cc] = p.act_percap_adaptationcosts[tt, cc] * p.pop_population[tt, cc]

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
