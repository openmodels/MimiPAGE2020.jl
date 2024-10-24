@defcomp GDP_growth begin
    # GDP: Gross domestic product $M
    # GRW: GDP growth rate %/year
    region            = Index()

    # Variables
    gdp               = Variable(index=[time, region], unit="\$M")
    cons_consumption  = Variable(index=[time, region], unit="\$million")
    cons_percap_consumption = Variable(index=[time, region], unit="\$/person")

    # Parameters
    y_year_0          = Parameter(unit="year")
    y_year            = Parameter(index=[time], unit="year")
    grw_gdpgrowthrate = Parameter(index=[time, region], unit="%/year") # From p.32 of Hope 2009
    save_savingsrate  = Parameter(unit="%", default=15.00) # pp33 PAGE09 documentation, "savings rate".
    pop_population_region    = Parameter(index=[time,region], unit="million person")

    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    # parameters and variables for growth effects
    gdp_leveleffect   = Parameter(index=[time, region], unit="\$M")
    isat_ImpactinclSaturationandAdaptation = Parameter(index=[time,region], unit="\$")
    lgdp_gdploss =  Variable(index=[time, region], unit="\$M")
    ge_growtheffects = Parameter(unit = "none", default =  0.)
    geadrate_growtheffects_adaptationrate = Parameter(unit = "none", default = 0.)
    geadpt_growtheffects_adapted = Variable(index = [time], unit = "none")
    grwnet_realizedgdpgrowth = Variable(index=[time, region], unit = "%/year")
    # bound variables
    use_convergence = Parameter(unit="none", default=1.)
    cbabs_pcconsumptionbound = Parameter(unit="\$/person", default=740.65)
    cbabsn_pcconsumptionbound_neighbourhood = Variable(unit="\$/person")
    cbaux1_pcconsumptionbound_auxiliary1 = Variable(unit="none")
    cbaux2_pcconsumptionbound_auxiliary2 = Variable(unit="none")
    cbreg_regionsatbound = Variable(index=[time, region], unit="regions")
    cons_consumption_noconvergence = Variable(index=[time, region], unit="\$million")
    cons_percap_consumption_noconvergence = Variable(index=[time, region], unit="\$/person")
    # switch to overwrite the growth effects parameter with empirical distribution
    ge_empirical_distribution = Parameter(index=[draw], unit="none")
    ge_use_empiricaldistribution = Parameter(unit="none", default=0.)
    ge_seed_empiricaldistribution = Parameter(unit="none", default=1.)
    # switch to shut off persistence for certain regions
    ge_regionswitch = Parameter(index=[region], unit="none")
    ge_use_regionswitch = Parameter(unit="none", default = 0.)
    ###############################################

    function run_timestep(p, v, d, t)

        if is_first(t)
            # calculate the lower consumption bound and the consumption level which triggers the convergence system
            v.cbabsn_pcconsumptionbound_neighbourhood = p.cbabs_pcconsumptionbound * 1.5

            # define auxiliary parameters for the convergence system to make formulas easier to read
            v.cbaux1_pcconsumptionbound_auxiliary1 = 2 * (p.cbabs_pcconsumptionbound - v.cbabsn_pcconsumptionbound_neighbourhood)
            v.cbaux2_pcconsumptionbound_auxiliary2 = 4 / v.cbaux1_pcconsumptionbound_auxiliary1

            # if the switch is set to one, overwrite the growth effects parameter with an empirical distribution, using the seed parameter
            if p.ge_use_empiricaldistribution == 1.
                Random.seed!(trunc(Int, p.ge_seed_empiricaldistribution))
                p.ge_growtheffects = p.ge_empirical_distribution[Random.rand(1:length(p.ge_empirical_distribution))]
            elseif p.ge_use_empiricaldistribution == 2. # set negative rho values to zero if switch set to two
                Random.seed!(trunc(Int, p.ge_seed_empiricaldistribution))
                p.ge_growtheffects = max(p.ge_empirical_distribution[Random.rand(1:length(p.ge_empirical_distribution))], 0)
            end
        end

        # calculate the growth effects parameter net of the assumed adaptation to damage persistence
        v.geadpt_growtheffects_adapted[t] = p.ge_growtheffects * (1 - p.geadrate_growtheffects_adaptationrate)^(p.y_year[t] - p.y_year_0)

        for r in d.region
            # eq.28 in Hope 2002
            if is_first(t)
                v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r]
                v.cons_consumption[t, r] = p.gdp_leveleffect[t, r] * (1 - p.save_savingsrate / 100)
                v.cons_percap_consumption[t, r] = v.cons_consumption[t, r] / p.pop_population_region[t, r]
                v.gdp[t, r] = p.gdp_leveleffect[t, r]
            else
                # if region switch is used, multiply the growth effect by the switch; otherwise, multiply by one
                v.grwnet_realizedgdpgrowth[t,r] = p.grw_gdpgrowthrate[t,r] - ifelse(p.ge_use_regionswitch == 1., p.ge_regionswitch[r], 1.) * v.geadpt_growtheffects_adapted[t] * p.isat_ImpactinclSaturationandAdaptation[t-1,r]
                v.gdp[t, r] = v.gdp[t-1, r] * (1 + (v.grwnet_realizedgdpgrowth[t,r]/100))^(p.y_year[t] - p.y_year[t-1])

                v.cons_consumption[t, r] = v.gdp[t, r] * (1 - p.save_savingsrate / 100)
                v.cons_percap_consumption[t, r] = v.cons_consumption[t, r] / p.pop_population_region[t, r]

                # let boundary take effect if pc consumption is in the neighbourhood of the boundary
                if p.use_convergence == 1.
                    if v.cons_percap_consumption[t,r] >= v.cbabsn_pcconsumptionbound_neighbourhood
                        v.cbreg_regionsatbound[t,r] = 0.
                        v.cons_consumption_noconvergence[t,r] = v.cons_consumption[t,r]
                        v.cons_percap_consumption_noconvergence[t,r] = v.cons_consumption_noconvergence[t,r] / p.pop_population_region[t,r]
                    else
                        # calculate the consumption level if there was no convergence system
                        v.cons_consumption_noconvergence[t,r] = v.cons_consumption_noconvergence[t - 1, r] * (1 + (v.grwnet_realizedgdpgrowth[t,r] / 100))^(p.y_year[t] - p.y_year[t - 1])
                        v.cons_percap_consumption_noconvergence[t,r] = v.cons_consumption_noconvergence[t,r] / p.pop_population_region[t,r]

                        # send the pc cconsumption on a logistic path convergenging against the bound
                        v.cons_percap_consumption[t,r] = v.cbabsn_pcconsumptionbound_neighbourhood - 0.5 * v.cbaux1_pcconsumptionbound_auxiliary1 +
                                            v.cbaux1_pcconsumptionbound_auxiliary1 * exp(v.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                    (v.cons_percap_consumption_noconvergence[t,r] - v.cbabsn_pcconsumptionbound_neighbourhood)) /
                                                                                (1 + exp(v.cbaux2_pcconsumptionbound_auxiliary2 *
                                                                                        (v.cons_percap_consumption_noconvergence[t,r] - v.cbabsn_pcconsumptionbound_neighbourhood)))

                    # recalculate all variables accordingly
                        v.cons_consumption[t, r] = v.cons_percap_consumption[t,r] * p.pop_population_region[t,r]
                        v.gdp[t, r] = v.cons_consumption[t, r] / (1 - p.save_savingsrate / 100)
                        v.grwnet_realizedgdpgrowth[t,r] = 100 * ((v.gdp[t, r] / v.gdp[t - 1, r])^(1 / (p.y_year[t] - p.y_year[t - 1])) - 1)

                        v.cbreg_regionsatbound[t,r] = 1.

                    end
                else
                    if v.cons_percap_consumption[t,r] < p.cbabs_pcconsumptionbound
                        v.cons_percap_consumption[t,r] = p.cbabs_pcconsumptionbound

                        # recalculate all variables accordingly
                        v.cons_consumption[t, r] = v.cons_percap_consumption[t,r] * p.pop_population_region[t,r]
                        v.gdp[t, r] = v.cons_consumption[t, r] / (1 - p.save_savingsrate / 100)
                        v.grwnet_realizedgdpgrowth[t,r] = 100 * ((v.gdp[t, r] / v.gdp[t - 1, r])^(1 / (p.y_year[t] - p.y_year[t - 1])) - 1)

                        v.cbreg_regionsatbound[t,r] = 1.
                    end
                end
            end

            v.lgdp_gdploss[t,r] = p.gdp_leveleffect[t,r] - v.gdp[t,r]

        end
    end
end
