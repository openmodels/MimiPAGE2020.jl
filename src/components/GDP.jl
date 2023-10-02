include("../utils/country_tools.jl")

@defcomp GDP begin
    # GDP: Gross domestic product $M
    # GRW: GDP growth rate %/year
    region = Index()
    country = Index()

    # Variables
    gdp               = Variable(index=[time, country], unit="\$M")
    gdp_region        = Variable(index=[time, region], unit="\$M")
    cons_consumption  = Variable(index=[time, region], unit="\$million")
    cons_percap_consumption = Variable(index=[time, region], unit="\$/person")
    cons_percap_consumption_0 = Variable(index=[region], unit="\$/person")
    yagg_periodspan = Variable(index=[time], unit="year")
    gdp0_initgdp_region = Variable(index=[region], unit="\$M")

    # Parameters
    y_year_0          = Parameter(unit="year")
    y_year            = Parameter(index=[time], unit="year")
    grw_gdpgrowthrate = Parameter(index=[time, region], unit="%/year") # From p.32 of Hope 2009
    gdp0_initgdp      = Parameter(index=[country], unit="\$M") # GDP in y_year_0
    save_savingsrate  = Parameter(unit="%", default=15.00) # pp33 PAGE09 documentation, "savings rate".
    pop0_initpopulation_region = Parameter(index=[region], unit="million person")
    pop_population    = Parameter(index=[time,region], unit="million person")

    # Saturation, used in impacts
    isat0_initialimpactfxnsaturation = Parameter(unit="unitless", default=20.0) # pp34 PAGE09 documentation
    isatg_impactfxnsaturation = Variable(unit="unitless")

    function init(p, v, d)
        byregion = countrytoregion(model, sum, p.gdp0_initgdp)
        for rr in d.region
            v.gdp0_initgdp_region[rr] = byregion[rr]
        end

        v.isatg_impactfxnsaturation = p.isat0_initialimpactfxnsaturation * (1 - p.save_savingsrate / 100)
        for rr in d.region
            v.cons_percap_consumption_0[rr] = (p.gdp0_initgdp_region[rr] / p.pop0_initpopulation_region[rr]) * (1 - p.save_savingsrate / 100)
        end
    end

    function run_timestep(p, v, d, t)

        # Analysis period ranges - required for abatemnt costs and equity weighting, from Hope (2006)
        if is_first(t)
            ylo_periodstart = p.y_year_0
        else
            ylo_periodstart = (p.y_year[t] + p.y_year[t - 1]) / 2
        end

        if t.t == length(p.y_year)
            yhi_periodend = p.y_year[t]
        else
            yhi_periodend = (p.y_year[t] + p.y_year[t + 1]) / 2
        end

        v.yagg_periodspan[t] = yhi_periodend - ylo_periodstart

        for cc in d.country
            # eq.28 in Hope 2002
            if is_first(t)
                v.gdp[t, cc] = p.gdp0_initgdp[cc] * (1 + (p.grw_gdpgrowthrate[t, cc] / 100))^(p.y_year[t] - p.y_year_0)
            else
                v.gdp[t, cc] = v.gdp[t - 1, cc] * (1 + (p.grw_gdpgrowthrate[t, cc] / 100))^(p.y_year[t] - p.y_year[t - 1])
            end
        end

        v.gdp_region[t, :] = countrytoregion(model, sum, v.gdp[t, :])
        for r in d.region
            v.cons_consumption[t, r] = v.gdp_region[t, r] * (1 - p.save_savingsrate / 100)
            v.cons_percap_consumption[t, r] = v.cons_consumption[t, r] / p.pop_population[t, r]
        end
    end
end
