@defcomp GDP_annual begin
    # GDP: Gross domestic product $M
    # GRW: GDP growth rate %/year
    region            = Index()
    year              = Index()

    # Variables
    gdp_ann               = Variable(index=[year, region], unit="\$M")
    cons_consumption_ann  = Variable(index=[year, region], unit="\$million")
    cons_percap_consumption_ann = Variable(index=[year, region], unit="\$/person")

    # Parameters
    y_year_0          = Parameter(unit="year")
    y_year_ann        = Parameter(index=[year], unit="year")
    grw_gdpgrowthrate = Parameter(index=[time, region], unit="%/year") # From p.32 of Hope 2009
    grw_gdpgrowthrate_ann = Variable(index=[year, region], unit="%/year")                                   # interpolation
    gdp_0             = Parameter(index=[region], unit="\$M") # GDP in y_year_0
    save_savingsrate  = Parameter(unit="%", default=15.00) # pp33 PAGE09 documentation, "savings rate".
    pop_population    = Parameter(index=[time,region], unit="million person")
    pop_population_ann = Variable(index=[year, region], unit="million person")                              # interpolation

    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    # parameters and variables for growth effects
    gdp_leveleffect_ann   = Variable(index=[year, region], unit="\$M")
    isat_ImpactinclSaturationandAdaptation_ann = Parameter(index=[year,region])                              # from MarketDamagesBurke (if default, otherwise MarketDamages)
    lgdp_gdploss_ann =  Variable(index=[year, region], unit="\$M")
    ge_growtheffects = Parameter(unit="none", default=0.)
    grwnet_realizedgdpgrowth_ann = Variable(index=[year, region], unit="%/year")
    # bound variables
    use_convergence = Parameter(unit="none", default=1.)
    cbabs_pcconsumptionbound = Parameter(unit="\$/person", default=740.65)
    cbabsn_pcconsumptionbound_neighbourhood = Parameter(unit="\$/person")
    cbaux1_pcconsumptionbound_auxiliary1 = Parameter(unit="none")
    cbaux2_pcconsumptionbound_auxiliary2 = Parameter(unit="none")
    cbreg_regionsatbound_ann = Variable(index=[year, region], unit="regions")
    cons_consumption_noconvergence_ann = Variable(index=[year, region], unit="\$million")
    cons_percap_consumption_noconvergence_ann = Variable(index=[year, region], unit="\$/person")
    ###############################################

    function run_timestep(p, v, d, t)

        interpolate_parameters_gdp(p, v, d, t)

        # calculate  for this specific year
        if is_first(t)
            for annual_year = 2015:(gettime(t))
                calc_gdp(p, v, d, t, annual_year)
            end
        else
            for annual_year = (gettime(t - 1) + 1):(gettime(t))
                calc_gdp(p, v, d, t, annual_year)
            end
        end

    end
end

function interpolate_parameters_gdp(p, v, d, t)
    # interpolation of parameters, see notes in run_timestep for why these parameters
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            yr = annual_year - 2015 + 1
            for r in d.region

                v.pop_population_ann[yr, r] = p.pop_population[t, r]
                v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r]

            end
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - gettime(t - 1)
            fraction_timestep = frac / ((gettime(t)) - (gettime(t - 1)))

            for r in d.region
                if use_linear
                    v.pop_population_ann[yr, r] = p.pop_population[t, r] * fraction_timestep + p.pop_population[t - 1, r] * (1 - fraction_timestep)
                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)
                elseif use_logburke
                    ## fully linear (partially because everything except for pop_population causes imaginary numbers (due to negative numbers)).
                    # linear
                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)
                    v.pop_population_ann[yr, r] = p.pop_population[t, r] * fraction_timestep + p.pop_population[t - 1, r] * (1 - fraction_timestep)
                elseif use_logpopulation
                    # linear
                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)

                    # log
                    v.pop_population_ann[yr, r] = p.pop_population[t, r]^fraction_timestep * p.pop_population[t - 1, r]^(1 - fraction_timestep)
                elseif use_logwherepossible
                    # linear
                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)

                    # log
                    v.pop_population_ann[yr, r] = p.pop_population[t, r]^fraction_timestep * p.pop_population[t - 1, r]^(1 - fraction_timestep)
                else
                    error("NO INTERPOLATION METHOD SELECTED! Specify linear or logarithmic interpolation.")
                end

            end
        end
    end
end

function calc_gdp(p, v, d, t, annual_year)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    for r in d.region
        # eq.28 in Hope 2002
        if is_first(t)
            v.gdp_ann[yr, r] = p.gdp_0[r] * (1 + (v.grw_gdpgrowthrate_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_0)

            v.grwnet_realizedgdpgrowth_ann[yr,r] = v.grw_gdpgrowthrate_ann[yr,r]
            v.gdp_leveleffect_ann[yr,r] = v.gdp_ann[yr,r]

            v.cons_consumption_ann[yr, r] = v.gdp_ann[yr, r] * (1 - p.save_savingsrate / 100)
            v.cons_percap_consumption_ann[yr, r] = v.cons_consumption_ann[yr, r] / v.pop_population_ann[yr, r]

        elseif isequal(gettime(t), 2030)
            v.grwnet_realizedgdpgrowth_ann[yr,r] = v.grw_gdpgrowthrate_ann[yr,r] - p.ge_growtheffects * p.isat_ImpactinclSaturationandAdaptation_ann[6,r]
            v.gdp_ann[yr, r] = v.gdp_ann[yr - 1, r] * (1 + (v.grwnet_realizedgdpgrowth_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_ann[yr - 1])
            v.gdp_leveleffect_ann[yr,r] = v.gdp_leveleffect_ann[yr - 1, r] *  (1 + (v.grw_gdpgrowthrate_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_ann[yr - 1])

            v.cons_consumption_ann[yr, r] = v.gdp_ann[yr, r] * (1 - p.save_savingsrate / 100)
            v.cons_percap_consumption_ann[yr, r] = v.cons_consumption_ann[yr, r] / v.pop_population_ann[yr, r]

            # let boundary take effect if pc consumption is in the neighbourhood of the boundary
            if p.use_convergence == 1.
                if v.cons_percap_consumption_ann[yr,r] >= p.cbabsn_pcconsumptionbound_neighbourhood
                    v.cbreg_regionsatbound_ann[yr,r] = 0.
                    v.cons_consumption_noconvergence_ann[yr,r] = v.cons_consumption_ann[yr,r]
                    v.cons_percap_consumption_noconvergence_ann[yr,r] = v.cons_consumption_noconvergence_ann[yr,r] / v.pop_population_ann[yr,r]
                else
                    # calculate the consumption level if there was no convergence system
                    v.cons_consumption_noconvergence_ann[yr,r] = v.cons_consumption_noconvergence_ann[yr - 1, r] * (1 + (v.grwnet_realizedgdpgrowth_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_ann[yr - 1])
                    v.cons_percap_consumption_noconvergence_ann[yr,r] = v.cons_consumption_noconvergence_ann[yr,r] / v.pop_population_ann[yr,r]

                    # send the pc cconsumption on a logistic path convergenging against the bound
                    v.cons_percap_consumption_ann[yr,r] = p.cbabsn_pcconsumptionbound_neighbourhood - 0.5 * p.cbaux1_pcconsumptionbound_auxiliary1 +
                                        p.cbaux1_pcconsumptionbound_auxiliary1 * exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                (v.cons_percap_consumption_noconvergence_ann[yr,r] - p.cbabsn_pcconsumptionbound_neighbourhood)) /
                                                                            (1 + exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                    (v.cons_percap_consumption_noconvergence_ann[yr,r] - p.cbabsn_pcconsumptionbound_neighbourhood)))

                # recalculate all variables accordingly
                    v.cons_consumption_ann[yr, r] = v.cons_percap_consumption_ann[yr,r] * v.pop_population_ann[yr,r]
                    v.gdp_ann[yr, r] = v.cons_consumption_ann[yr, r] / (1 - p.save_savingsrate / 100)
                    v.grwnet_realizedgdpgrowth_ann[yr,r] = 100 * ((v.gdp_ann[yr, r] / v.gdp_ann[yr - 1, r])^(1 / (p.y_year_ann[yr] - p.y_year_ann[yr - 1])) - 1)

                    v.cbreg_regionsatbound_ann[yr,r] = 1.

                end
            else
                if v.cons_percap_consumption_ann[yr,r] < p.cbabs_pcconsumptionbound
                    v.cons_percap_consumption_ann[yr,r] = p.cbabs_pcconsumptionbound

                    # recalculate all variables accordingly
                    v.cons_consumption_ann[yr, r] = v.cons_percap_consumption_ann[yr,r] * v.pop_population_ann[yr,r]
                    v.gdp_ann[yr, r] = v.cons_consumption_ann[yr, r] / (1 - p.save_savingsrate / 100)
                    v.grwnet_realizedgdpgrowth_ann[yr,r] = 100 * ((v.gdp_ann[yr, r] / v.gdp_ann[yr - 1, r])^(1 / (p.y_year_ann[yr] - p.y_year_ann[yr - 1])) - 1)

                    v.cbreg_regionsatbound_ann[yr,r] = 1.
                end
            end


        else
            lag = gettime(t) - gettime(t - 1)
            v.grwnet_realizedgdpgrowth_ann[yr,r] = v.grw_gdpgrowthrate_ann[yr,r] - p.ge_growtheffects * p.isat_ImpactinclSaturationandAdaptation_ann[yr - lag,r]
            v.gdp_ann[yr, r] = v.gdp_ann[yr - 1, r] * (1 + (v.grwnet_realizedgdpgrowth_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_ann[yr - 1])
            v.gdp_leveleffect_ann[yr,r] = v.gdp_leveleffect_ann[yr - 1, r] *  (1 + (v.grw_gdpgrowthrate_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_ann[yr - 1])

            v.cons_consumption_ann[yr, r] = v.gdp_ann[yr, r] * (1 - p.save_savingsrate / 100)
            v.cons_percap_consumption_ann[yr, r] = v.cons_consumption_ann[yr, r] / v.pop_population_ann[yr, r]

            # let boundary take effect if pc consumption is in the neighbourhood of the boundary
            if p.use_convergence == 1.
                if v.cons_percap_consumption_ann[yr,r] >= p.cbabsn_pcconsumptionbound_neighbourhood
                    v.cbreg_regionsatbound_ann[yr,r] = 0.
                    v.cons_consumption_noconvergence_ann[yr,r] = v.cons_consumption_ann[yr,r]
                    v.cons_percap_consumption_noconvergence_ann[yr,r] = v.cons_consumption_noconvergence_ann[yr,r] / v.pop_population_ann[yr,r]
                else
                    # calculate the consumption level if there was no convergence system
                    v.cons_consumption_noconvergence_ann[yr,r] = v.cons_consumption_noconvergence_ann[yr - 1, r] * (1 + (v.grwnet_realizedgdpgrowth_ann[yr,r] / 100))^(p.y_year_ann[yr] - p.y_year_ann[yr - 1])
                    v.cons_percap_consumption_noconvergence_ann[yr,r] = v.cons_consumption_noconvergence_ann[yr,r] / v.pop_population_ann[yr,r]

                    # send the pc cconsumption on a logistic path convergenging against the bound
                    v.cons_percap_consumption_ann[yr,r] = p.cbabsn_pcconsumptionbound_neighbourhood - 0.5 * p.cbaux1_pcconsumptionbound_auxiliary1 +
                                        p.cbaux1_pcconsumptionbound_auxiliary1 * exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                (v.cons_percap_consumption_noconvergence_ann[yr,r] - p.cbabsn_pcconsumptionbound_neighbourhood)) /
                                                                            (1 + exp(p.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                    (v.cons_percap_consumption_noconvergence_ann[yr,r] - p.cbabsn_pcconsumptionbound_neighbourhood)))

                # recalculate all variables accordingly
                    v.cons_consumption_ann[yr, r] = v.cons_percap_consumption_ann[yr,r] * v.pop_population_ann[yr,r]
                    v.gdp_ann[yr, r] = v.cons_consumption_ann[yr, r] / (1 - p.save_savingsrate / 100)
                    v.grwnet_realizedgdpgrowth_ann[yr,r] = 100 * ((v.gdp_ann[yr, r] / v.gdp_ann[yr - 1, r])^(1 / (p.y_year_ann[yr] - p.y_year_ann[yr - 1])) - 1)

                    v.cbreg_regionsatbound_ann[yr,r] = 1.

                end
            else
                if v.cons_percap_consumption_ann[yr,r] < p.cbabs_pcconsumptionbound
                    v.cons_percap_consumption_ann[yr,r] = p.cbabs_pcconsumptionbound

                    # recalculate all variables accordingly
                    v.cons_consumption_ann[yr, r] = v.cons_percap_consumption_ann[yr,r] * v.pop_population_ann[yr,r]
                    v.gdp_ann[yr, r] = v.cons_consumption_ann[yr, r] / (1 - p.save_savingsrate / 100)
                    v.grwnet_realizedgdpgrowth_ann[yr,r] = 100 * ((v.gdp_ann[yr, r] / v.gdp_ann[yr - 1, r])^(1 / (p.y_year_ann[yr] - p.y_year_ann[yr - 1])) - 1)

                    v.cbreg_regionsatbound_ann[yr,r] = 1.
                end
            end
        end

        v.lgdp_gdploss_ann[yr,r] = v.gdp_leveleffect_ann[yr,r] - v.gdp_ann[yr,r]
    end



end
