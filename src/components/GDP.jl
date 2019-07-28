@defcomp GDP begin
# GDP: Gross domestic product $M
# GRW: GDP growth rate %/year
    region            = Index()

    # Variables
    gdp               = Variable(index=[time, region], unit="\$M")
    gdp_leveleffect   = Variable(index=[time, region], unit="\$M")
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

    # parameters and variables for growth effects
    isat_ImpactinclSaturationandAdaptation = Parameter(index=[time,region], unit = "%GDP")
    lgdp_gdploss =  Variable(index=[time, region], unit="\$M")
    ge_growtheffects = Parameter(unit = "none", default =  0.)
    grwnet_realizedgdpgrowth = Variable(index=[time, region], unit = "%/year")
    # bound variables
    cbshare_pcconsumptionboundshare = Parameter(unit = "%", default = 1)
    cbabs_pcconsumptionbound = Variable(unit = "\$/person")
    gdpabs_pcgdpbound = Variable(unit = "\$/person")
    cbreg_regionsatbound = Variable(unit = "regions")

    function init(p, v, d)

        v.isatg_impactfxnsaturation = p.isat0_initialimpactfxnsaturation * (1 - p.save_savingsrate/100)
        for rr in d.region
            v.cons_percap_consumption_0[rr] = (p.gdp_0[rr] / p.pop0_initpopulation[rr])*(1 - p.save_savingsrate / 100)
        end
    end

    function run_timestep(p, v, d, t)

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

        if is_first(t)
            v.cbreg_regionsatbound = 0
        end


        for r in d.region
            #eq.28 in Hope 2002
            if is_first(t)
                v.gdp[t, r] = p.gdp_0[r] * (1 + (p.grw_gdpgrowthrate[t,r]/100))^(p.y_year[t] - p.y_year_0)
                v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r]
                v.gdp_leveleffect[t,r] = v.gdp[t,r]

                v.cbabs_pcconsumptionbound = (p.cbshare_pcconsumptionboundshare/100) * v.cons_percap_consumption_0[1]
                v.gdpabs_pcgdpbound = v.cbabs_pcconsumptionbound/(1-p.save_savingsrate/100)
            else
                v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r] - p.ge_growtheffects * p.isat_ImpactinclSaturationandAdaptation[t-1,r]
                v.gdp[t, r] = v.gdp[t-1, r] * (1 + (v.grwnet_realizedgdpgrowth[t,r]/100))^(p.y_year[t] - p.y_year[t-1])
                v.gdp_leveleffect[t,r] = v.gdp_leveleffect[t-1, r] *  (1 + (p.grw_gdpgrowthrate[t,r]/100))^(p.y_year[t] - p.y_year[t-1])

                # let boundary take effect if necessary
                if v.gdp[t,r]/p.pop_population[t,r] < v.gdpabs_pcgdpbound
                    v.gdp[t,r] = v.gdpabs_pcgdpbound * p.pop_population[t,r]
                end
            end
            v.cons_consumption[t, r] = v.gdp[t, r] * (1 - p.save_savingsrate / 100)
            v.cons_percap_consumption[t, r] = v.cons_consumption[t, r] / p.pop_population[t, r]

            v.lgdp_gdploss[t,r] = v.gdp_leveleffect[t,r] - v.gdp[t,r]

            if is_last(t)
                v.cbreg_regionsatbound = v.cbreg_regionsatbound + (v.gdp[t,r] == v.gdpabs_pcgdpbound * p.pop_population[t,r])
            end
        end
    end
end
