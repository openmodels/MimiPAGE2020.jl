@defcomp GDP begin
# GDP: Gross domestic product $M
# GRW: GDP growth rate %/year
    region            = Index()

    # Variables
    gdp               = Variable(index=[time, region], unit="\$M")
    gdp_leveleffect = Variable(index=[time, region], unit="\$M")
    cons_consumption  = Variable(index=[time, region], unit="\$million")
    cons_percap_consumption = Variable(index=[time, region], unit="\$/person")
    cons_percap_consumption_0 = Variable(index=[region], unit="\$/person")
    yagg_periodspan = Variable(index=[time], unit="year")

    # Parameters
    y_year_0          = Parameter(unit="year")
    y_year            = Parameter(index=[time], unit="year")
    grw_gdpgrowthrate = Parameter(index=[time, region], unit="%/year") #From p.32 of Hope 2009
    gdp_0             = Parameter(index=[region], unit="\$M") #GDP in y_year_0
    save_savingsrate  = Parameter(unit="%", default=15.00) #pp33 PAGE09 documentation, "savings rate".
    pop0_initpopulation = Parameter(index=[region], unit="million person")
    pop_population    = Parameter(index=[time,region],unit="million person")

    # Saturation, used in impacts
    isat0_initialimpactfxnsaturation = Parameter(unit="unitless", default=20.0) #pp34 PAGE09 documentation
    isatg_impactfxnsaturation = Variable(unit="unitless")

    # market damages as %GDP, for growth effects feedback
    isat_ImpactinclSaturationandAdaptation = Parameter(index=[time,region], unit = "%GDP")
    isat_satdiscimpact = Parameter(index=[time,region], unit="%GDP")
    ge_growtheffects = Parameter(unit = "none", default =  0.)
    gedisc_included = Parameter(unit = "none", default = 0.)

    # new variables containing the difference to unperturbed GDP and the realized growth rate net of CC damages
    lgdp_gdploss =  Variable(index=[time, region], unit="\$M")
    grwnet_realizedgdpgrowth = Variable(index=[time, region], unit = "%/year")

    function init(p, v, d)

        v.isatg_impactfxnsaturation = p.isat0_initialimpactfxnsaturation * (1 - p.save_savingsrate/100)
        for rr in d.region
            v.cons_percap_consumption_0[rr] = (p.gdp_0[rr] / p.pop0_initpopulation[rr])*(1 - p.save_savingsrate / 100)
        end
    end

    function run_timestep(p, v, d, t)

        if @isdefined ge_master
            if isa(ge_master, Number) && ge_master <= 1. && ge_master >= 0.
                p.ge_growtheffects = ge_master
            else
                error("The parameter ge_master must be a number between 0 and 1. Please adjust the parameter")
            end
        end

        if @isdefined gedisc_master
            if gedisc_master == "Yes"
                p.gedisc_included = 1.0
            elseif gedisc_master == "No"
                p.gedisc_included = 0.0
            else
                error("The parameter gedisc_master must be set to Yes or No. Please adjust the parameter")
            end
        end

        # Analysis period ranges - required for abatemnt costs and equity weighting, from Hope (2006)
        if is_first(t)
            ylo_periodstart = p.y_year_0
        else
            ylo_periodstart = (p.y_year[t] + p.y_year[t-1]) / 2
        end

        if t.t == length(p.y_year)
            yhi_periodend = p.y_year[t]
        else
            yhi_periodend = (p.y_year[t] + p.y_year[t+1]) / 2
        end

        v.yagg_periodspan[t] = yhi_periodend- ylo_periodstart


        for r in d.region
            #eq.28 in Hope 2002
            if is_first(t)
                # compute the actually realized growth rate and the resulting GDP (in first period equal to scenario growth)
                v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r]
                v.gdp[t, r] = p.gdp_0[r] * (1 + (v.grwnet_realizedgdpgrowth[t,r]/100))^(p.y_year[t] - p.y_year_0)
                # compute the counterfactual scenario if there had been no growth effects
                v.gdp_leveleffect[t, r] = v.gdp[t, r]
            else
                if p.gedisc_included == 0.0
                    v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r] - p.ge_growtheffects * p.isat_ImpactinclSaturationandAdaptation[t-1,r]
                else
                    v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r] - p.ge_growtheffects * (p.isat_ImpactinclSaturationandAdaptation[t-1,r] + p.isat_satdiscimpact[t-1,r])
                end
                v.gdp[t, r] = v.gdp[t-1, r] * (1 + (v.grwnet_realizedgdpgrowth[t,r] / 100))^(p.y_year[t] - p.y_year[t-1])
                v.gdp_leveleffect[t, r] = v.gdp_leveleffect[t-1, r] * (1 + (p.grw_gdpgrowthrate[t,r]/100))^(p.y_year[t] - p.y_year[t-1])
            end
            v.cons_consumption[t, r] = v.gdp[t, r] * (1 - p.save_savingsrate / 100)
            v.cons_percap_consumption[t, r] = v.cons_consumption[t, r] / p.pop_population[t, r]

            # compute the difference between realized and unperturbed counterfactual GDP
            v.lgdp_gdploss[t,r] = v.gdp_leveleffect[t,r] - v.gdp[t,r]

        end
    end
end
