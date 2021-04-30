function interpolate_parameters_equityweighting(p, v, d, t)

    # interpolation of parameters, see notes in run_timestep for why these parameters
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            yr = annual_year - 2015 + 1
            for r in d.region
                v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r]
            end
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - gettime(t - 1)
            fraction_timestep = frac / ((gettime(t)) - (gettime(t - 1)))

            for r in d.region
                if use_linear || use_logburke || use_logpopulation || use_logwherepossible
                    v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r] * fraction_timestep + p.popgrw_populationgrowth[t - 1, r] * (1 - fraction_timestep)
                else
                    error("NO INTERPOLATION METHOD SELECTED! Specify linear or logarithmic interpolation.")
                end

            end
        end
    end
end

function calc_equityweighting(p, v, d, t, annual_year)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    v.df_utilitydiscountfactor_ann[yr] = (1 + p.ptp_timepreference / 100)^(-(p.y_year_ann[yr] - p.y_year_0))

    if p.discfix_fixediscountrate != 0.
        v.df_utilitydiscountfactor_ann[yr] = (1 + p.discfix_fixediscountrate / 100)^(-(p.y_year_ann[yr] - p.y_year_0))
    end


    for r in d.region

        ## Gas Costs Accounting
        # Weighted costs (Page 23 of Hope 2009)
        v.wtct_percap_weightedcosts_ann[yr, r] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_consumption_ann[yr, r]^(1 - p.emuc_utilityconvexity) - (p.cons_percap_consumption_ann[yr, r] - p.tct_percap_totalcosts_total_ann[yr, r] < 0.01 * p.cons_percap_consumption_0[1] ? 0.01 * p.cons_percap_consumption_0[1] : p.cons_percap_consumption_ann[yr, r] - p.tct_percap_totalcosts_total_ann[yr, r])^(1 - p.emuc_utilityconvexity))

        # Add these into consumption
        v.eact_percap_weightedadaptationcosts_ann[yr, r] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_consumption_ann[yr, r]^(1 - p.emuc_utilityconvexity) - (p.cons_percap_consumption_ann[yr, r] - p.act_percap_adaptationcosts_ann[yr, r] < 0.01 * p.cons_percap_consumption_0[1] ? 0.01 * p.cons_percap_consumption_0[1] : p.cons_percap_consumption_ann[yr, r] - p.act_percap_adaptationcosts_ann[yr, r])^(1 - p.emuc_utilityconvexity))

        # Do partial weighting
        if p.equity_proportion == 0
            v.pct_percap_partiallyweighted_ann[yr, r] = p.tct_percap_totalcosts_total_ann[yr, r]
            v.wact_percap_partiallyweighted_ann[yr, r] = p.act_percap_adaptationcosts_ann[yr, r]
        else
            v.pct_percap_partiallyweighted_ann[yr, r] = (1 - p.equity_proportion) * p.tct_percap_totalcosts_total_ann[yr, r] + p.equity_proportion * v.wtct_percap_weightedcosts_ann[yr, r]
            v.wact_percap_partiallyweighted_ann[yr, r] = (1 - p.equity_proportion) * p.act_percap_adaptationcosts_ann[yr, r] + p.equity_proportion * v.eact_percap_weightedadaptationcosts_ann[yr, r]
        end

        v.pct_partiallyweighted_ann[yr, r] = v.pct_percap_partiallyweighted_ann[yr, r] * p.pop_population_ann[yr, r]
        v.wact_partiallyweighted_ann[yr, r] = v.wact_percap_partiallyweighted_ann[yr, r] * p.pop_population_ann[yr, r]

        # Discount rate calculations
        v.dr_discountrate_ann[yr, r] = p.ptp_timepreference + p.emuc_utilityconvexity * (p.grwnet_realizedgdpgrowth_ann[yr, r] - v.popgrw_populationgrowth_ann[yr, r])

        if p.discfix_fixediscountrate != 0.
            v.dr_discountrate_ann[yr, r] = p.discfix_fixediscountrate
        end

        v.yp_yearsperiod_ann[yr] = 1 # every timestep is 1 year long.

        if is_first(t)
            v.dfc_consumptiondiscountrate_ann[yr, r] = (1 + v.dr_discountrate_ann[yr, r] / 100)^(-v.yp_yearsperiod_ann[yr])
        else
            v.dfc_consumptiondiscountrate_ann[yr, r] = v.dfc_consumptiondiscountrate_ann[yr - 1, r] * (1 + v.dr_discountrate_ann[yr, r] / 100)^(-v.yp_yearsperiod_ann[yr])
        end

        # Discounted costs
        if p.equity_proportion == 0
            v.pcdt_partiallyweighted_discounted_ann[yr, r] = v.pct_partiallyweighted_ann[yr, r] * v.dfc_consumptiondiscountrate_ann[yr, r]
            v.wacdt_partiallyweighted_discounted_ann[yr, r] = p.act_adaptationcosts_total_ann[yr, r] * v.dfc_consumptiondiscountrate_ann[yr, r]
        else
            v.pcdt_partiallyweighted_discounted_ann[yr, r] = v.pct_partiallyweighted_ann[yr, r] * v.df_utilitydiscountfactor_ann[yr]
            v.wacdt_partiallyweighted_discounted_ann[yr, r] = v.wact_partiallyweighted_ann[yr, r] * v.df_utilitydiscountfactor_ann[yr]
        end

        v.pcdat_partiallyweighted_discountedaggregated_ann[yr, r] = v.pcdt_partiallyweighted_discounted_ann[yr, r]

        # calculate the total damages due to impacts
        v.currentdam_currentdamages_ann[yr, r] = (p.cons_percap_aftercosts_ann[yr, r] - p.rcons_percap_dis_ann[yr, r]) * p.pop_population_ann[yr, r]
        v.currentdampc_percapitacurrentdamages_ann[yr, r] = v.currentdam_currentdamages_ann[yr, r] / p.pop_population_ann[yr, r]
        v.damshare_currentdamagesshare_ann[yr, r] = 100 * v.currentdampc_percapitacurrentdamages_ann[yr, r] / p.cons_percap_aftercosts_ann[yr, r]

        # if damages including GDP losses exceed current consumption levels, calculate the share for equity weighting based on the convergence system
        v.eqwshare_shareofweighteddamages_noconvergence_ann[yr,r] = (v.currentdam_currentdamages_ann[yr, r] + p.lgdp_gdploss_ann[yr,r]) / (p.cons_percap_aftercosts_ann[yr, r] * p.pop_population_ann[yr, r])

        if p.use_convergence == 1.
            if v.eqwshare_shareofweighteddamages_noconvergence_ann[yr,r] > p.eqwboundn_maxshareofweighteddamages_neighbourhood
                v.eqwshare_shareofweighteddamages_ann[yr,r] = p.eqwboundn_maxshareofweighteddamages_neighbourhood - 0.5 * v.eqwaux1_weighteddamages_auxiliary1 +
                                v.eqwaux1_weighteddamages_auxiliary1 * exp(v.eqwaux2_weighteddamages_auxiliary2 *
                                                                        (v.eqwshare_shareofweighteddamages_noconvergence_ann[yr,r] - p.eqwboundn_maxshareofweighteddamages_neighbourhood)) /
                                                                    (1 + exp(v.eqwaux2_weighteddamages_auxiliary2 *
                                                                            (v.eqwshare_shareofweighteddamages_noconvergence_ann[yr,r] - p.eqwboundn_maxshareofweighteddamages_neighbourhood)))
                # for very large excess damages, exp(...) becomes infite and the convergence system returns NaN. In this case, simply set eqwshare to the upper bound
                if isnan(v.eqwshare_shareofweighteddamages_ann[yr,r])
                    v.eqwshare_shareofweighteddamages_ann[yr,r] = p.eqwbound_maxshareofweighteddamages
                end

                v.excdam_excessdamages_ann[yr, r] =  max(0, v.currentdam_currentdamages_ann[yr, r] + p.lgdp_gdploss_ann[yr,r] - v.eqwshare_shareofweighteddamages_ann[yr,r] * p.cons_percap_aftercosts_ann[yr, r] * p.pop_population_ann[yr, r])
            else
                v.excdam_excessdamages_ann[yr, r] =  0
            end
        else
            # use hard boundaries if use_convergence is not set to 1
            v.eqwshare_shareofweighteddamages_ann[yr,r] = min(v.eqwshare_shareofweighteddamages_noconvergence_ann[yr,r], p.eqwbound_maxshareofweighteddamages)
            v.excdam_excessdamages_ann[yr, r] =  max(0, v.currentdam_currentdamages_ann[yr, r] + p.lgdp_gdploss_ann[yr,r] - v.eqwshare_shareofweighteddamages_ann[yr,r] * p.cons_percap_aftercosts_ann[yr, r] * p.pop_population_ann[yr, r])
        end

        ## Equity weighted impacts (end of page 28, Hope 2009)
        if p.lossinc_includegdplosses == 0. && p.equity_proportion == 0.
            v.wit_partiallyweighted_ann[yr, r] = (p.cons_percap_aftercosts_ann[yr, r]  - p.rcons_percap_dis_ann[yr, r]) * p.pop_population_ann[yr, r]
            v.widt_partiallyweighted_discounted_ann[yr, r] = v.wit_partiallyweighted_ann[yr, r] * v.dfc_consumptiondiscountrate_ann[yr, r]
        elseif p.lossinc_includegdplosses == 0. && p.equity_proportion == 1.
            v.wit_partiallyweighted_ann[yr, r] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts_ann[yr, r]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis_ann[yr, r]^(1 - p.emuc_utilityconvexity)) * p.pop_population_ann[yr, r]
            v.widt_partiallyweighted_discounted_ann[yr, r] = v.wit_partiallyweighted_ann[yr, r] * v.df_utilitydiscountfactor_ann[yr]
        elseif p.lossinc_includegdplosses == 1. && p.equity_proportion == 0.
            v.wit_partiallyweighted_ann[yr, r] = (p.cons_percap_aftercosts_ann[yr, r]  - p.rcons_percap_dis_ann[yr, r]) * p.pop_population_ann[yr, r] + p.lgdp_gdploss_ann[yr, r]
            v.widt_partiallyweighted_discounted_ann[yr, r] = v.wit_partiallyweighted_ann[yr, r] * v.dfc_consumptiondiscountrate_ann[yr, r]
        elseif p.lossinc_includegdplosses == 1. && p.equity_proportion == 1.
            if v.excdam_excessdamages_ann[yr, r] == 0
                v.wit_partiallyweighted_ann[yr, r] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts_ann[yr, r]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis_ann[yr, r]^(1 - p.emuc_utilityconvexity)) * p.pop_population_ann[yr, r]
                v.widt_partiallyweighted_discounted_ann[yr, r] = v.wit_partiallyweighted_ann[yr, r] * v.df_utilitydiscountfactor_ann[yr]
            else
                v.wit_partiallyweighted_ann[yr, r] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts_ann[yr, r]^(1 - p.emuc_utilityconvexity) - ((1 - v.eqwshare_shareofweighteddamages_ann[yr,r]) * p.cons_percap_aftercosts_ann[yr, r])^(1 - p.emuc_utilityconvexity)) * p.pop_population_ann[yr, r]
                v.widt_partiallyweighted_discounted_ann[yr, r] = v.wit_partiallyweighted_ann[yr, r] * v.df_utilitydiscountfactor_ann[yr]  + v.excdam_excessdamages_ann[yr, r] *  v.dfc_consumptiondiscountrate_ann[yr, r]
            end
        end

        v.excdampv_excessdamagespresvalue_ann[yr, r] = v.excdam_excessdamages_ann[yr, r] *  v.dfc_consumptiondiscountrate_ann[yr, r]

        v.addt_equityweightedimpact_discountedaggregated_ann[yr, r] = v.widt_partiallyweighted_discounted_ann[yr, r]
        v.aact_equityweightedadaptation_discountedaggregated_ann[yr, r] = v.wacdt_partiallyweighted_discounted_ann[yr, r]

    end

    v.pct_g_partiallyweighted_global_ann[yr] = sum(v.pct_partiallyweighted_ann[yr, :])
    v.pcdt_g_partiallyweighted_discountedglobal_ann[yr] = sum(v.pcdt_partiallyweighted_discounted_ann[yr, :])
    v.tpc_totalaggregatedcosts_ann = v.tpc_totalaggregatedcosts_ann + sum(v.pcdat_partiallyweighted_discountedaggregated_ann[yr, :])

    v.addt_gt_equityweightedimpact_discountedglobal_ann = v.addt_gt_equityweightedimpact_discountedglobal_ann + sum(v.addt_equityweightedimpact_discountedaggregated_ann[yr, :])

    v.tac_totaladaptationcosts_ann = v.tac_totaladaptationcosts_ann + sum(v.aact_equityweightedadaptation_discountedaggregated_ann[yr, :])

    v.td_totaldiscountedimpacts_ann = min(v.addt_gt_equityweightedimpact_discountedglobal_ann, p.civvalue_civilizationvalue)
    v.td_totaldiscountedimpacts_ann_yr[yr] = v.td_totaldiscountedimpacts_ann # for saving as a timeseries for possible post-analysis

    # Total effect of climate change
    v.te_totaleffect_ann = min(v.td_totaldiscountedimpacts_ann + v.tpc_totalaggregatedcosts_ann + v.tac_totaladaptationcosts_ann, p.civvalue_civilizationvalue)
    v.te_totaleffect_ann_yr[yr] = v.te_totaleffect_ann # for saving as a timeseries for possible post-analysis
end

@defcomp EquityWeighting begin
    region = Index()
    year = Index()

    # Basic information
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")
    y_year_ann = Parameter(index=[year], unit="year")

    # Impacts across all gases
    pop_population = Parameter(index=[time, region], unit="million person")
    pop_population_ann = Parameter(index=[year, region], unit="million person")

    # Total and Per-Capita Abatement and Adaptation Costs
    tct_percap_totalcosts_total = Parameter(index=[time, region], unit="\$/person")
    tct_percap_totalcosts_total_ann = Parameter(index=[year, region], unit="\$/person")
    act_adaptationcosts_total = Parameter(index=[time, region], unit="\$million")
    act_adaptationcosts_total_ann = Parameter(index=[year, region], unit="\$million")
    act_percap_adaptationcosts = Parameter(index=[time, region], unit="\$/person")
    act_percap_adaptationcosts_ann = Parameter(index=[year, region], unit="\$/person")


    # Consumption
    cons_percap_consumption_0 = Parameter(index=[region], unit="\$/person")
    cons_percap_consumption = Parameter(index=[time, region], unit="\$/person") # Called "CONS_PER_CAP"
    cons_percap_consumption_ann = Parameter(index=[year, region], unit="\$/person")
    cons_percap_aftercosts = Parameter(index=[time, region], unit="\$/person")
    cons_percap_aftercosts_ann = Parameter(index=[year, region], unit="\$/person")

    # Calculation of weighted costs
    emuc_utilityconvexity = Parameter(unit="none", default=1.1666666666666667)

    wtct_percap_weightedcosts = Variable(index=[time, region], unit="\$/person")
    wtct_percap_weightedcosts_ann = Variable(index=[year, region], unit="\$/person")
    eact_percap_weightedadaptationcosts = Variable(index=[time, region], unit="\$/person")
    eact_percap_weightedadaptationcosts_ann = Variable(index=[year, region], unit="\$/person")
    wact_percap_partiallyweighted = Variable(index=[time, region], unit="\$/person")
    wact_percap_partiallyweighted_ann = Variable(index=[year, region], unit="\$/person")
    wact_partiallyweighted = Variable(index=[time, region], unit="\$million")
    wact_partiallyweighted_ann = Variable(index=[year, region], unit="\$million")

    # Amount of equity weighting variable (0, (0, 1), or 1)
    equity_proportion = Parameter(unit="fraction", default=1.0)

    pct_percap_partiallyweighted = Variable(index=[time, region], unit="\$/person")
    pct_percap_partiallyweighted_ann = Variable(index=[year, region], unit="\$/person")
    pct_partiallyweighted = Variable(index=[time, region], unit="\$million")
    pct_partiallyweighted_ann = Variable(index=[year, region], unit="\$million")
    pct_g_partiallyweighted_global = Variable(index=[time], unit="\$million")
    pct_g_partiallyweighted_global_ann = Variable(index=[year], unit="\$million")

    # Discount rates
    ptp_timepreference = Parameter(unit="%/year", default=1.0333333333333334) # <0.1,1, 2>
    popgrw_populationgrowth = Parameter(index=[time, region], unit="%/year")
    popgrw_populationgrowth_ann = Variable(index=[year, region], unit="%/year")

    dr_discountrate = Variable(index=[time, region], unit="%/year")
    dr_discountrate_ann = Variable(index=[year, region], unit="%/year")
    yp_yearsperiod = Variable(index=[time], unit="year") # defined differently from yagg
    yp_yearsperiod_ann = Variable(index=[year], unit="year")
    dfc_consumptiondiscountrate = Variable(index=[time, region], unit="1/year")
    dfc_consumptiondiscountrate_ann = Variable(index=[year, region], unit="1/year")

    df_utilitydiscountfactor = Variable(index=[time], unit="fraction")
    df_utilitydiscountfactor_ann = Variable(index=[year], unit="fraction")

    # Discounted costs
    pcdt_partiallyweighted_discounted = Variable(index=[time, region], unit="\$million")
    pcdt_partiallyweighted_discounted_ann = Variable(index=[year, region], unit="\$million")
    pcdt_g_partiallyweighted_discountedglobal = Variable(index=[time], unit="\$million")
    pcdt_g_partiallyweighted_discountedglobal_ann = Variable(index=[year], unit="\$million")

    pcdat_partiallyweighted_discountedaggregated = Variable(index=[time, region], unit="\$million")
    pcdat_partiallyweighted_discountedaggregated_ann = Variable(index=[year, region], unit="\$million")
    tpc_totalaggregatedcosts = Variable(unit="\$million")
    tpc_totalaggregatedcosts_ann = Variable(unit="\$million")

    wacdt_partiallyweighted_discounted = Variable(index=[time, region], unit="\$million")
    wacdt_partiallyweighted_discounted_ann = Variable(index=[year, region], unit="\$million")


    # Equity weighted impact totals
    rcons_percap_dis = Parameter(index=[time, region], unit="\$/person")
    rcons_percap_dis_ann = Parameter(index=[year, region], unit="\$/person")

    wit_partiallyweighted = Variable(index=[time, region], unit="\$million")
    wit_partiallyweighted_ann = Variable(index=[year, region], unit="\$million")
    widt_partiallyweighted_discounted = Variable(index=[time, region], unit="\$million")
    widt_partiallyweighted_discounted_ann = Variable(index=[year, region], unit="\$million")

    yagg_periodspan = Parameter(index=[time], unit="year")
    yagg_periodspan_ann = Variable(index=[year], unit="year")

    addt_equityweightedimpact_discountedaggregated = Variable(index=[time, region], unit="\$million")
    addt_equityweightedimpact_discountedaggregated_ann = Variable(index=[year, region], unit="\$million")
    addt_gt_equityweightedimpact_discountedglobal = Variable(unit="\$million")
    addt_gt_equityweightedimpact_discountedglobal_ann = Variable(unit="\$million")

    civvalue_civilizationvalue = Parameter(unit="\$million", default=6.1333333333333336e10) # Called "CIV_VALUE"
    td_totaldiscountedimpacts = Variable(unit="\$million")
    td_totaldiscountedimpacts_ts = Variable(index=[time], unit="\$million") # for analysis
    td_totaldiscountedimpacts_ann = Variable(unit="\$million")
    td_totaldiscountedimpacts_ann_yr = Variable(index=[year], unit="\$million") # for analysis

    aact_equityweightedadaptation_discountedaggregated = Variable(index=[time, region], unit="\$million")
    aact_equityweightedadaptation_discountedaggregated_ann = Variable(index=[year, region], unit="\$million")
    tac_totaladaptationcosts = Variable(unit="\$million")
    tac_totaladaptationcosts_ann = Variable(unit="\$million")

    # Final result: total effect of climate change
    te_totaleffect = Variable(unit="\$million")
    te_totaleffect_ann = Variable(unit="\$million")
    te_totaleffect_ann_yr = Variable(index=[year], unit="\$million") # for analysis


    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    # additional paramters and variables for growth effects and boundaries
    grwnet_realizedgdpgrowth = Parameter(index=[time, region], unit="%/year")
    grwnet_realizedgdpgrowth_ann = Parameter(index=[year, region], unit="%/year")                  # interpolated in GDP
    lgdp_gdploss =  Parameter(index=[time, region], unit="\$M")
    lgdp_gdploss_ann =  Parameter(index=[year, region], unit="\$M")                                  # interpolated in GDP
    lossinc_includegdplosses = Parameter(unit="none", default=1.)
    excdam_excessdamages = Variable(index=[time,region], unit="\$million")
    excdam_excessdamages_ann = Variable(index=[year,region], unit="\$million")
    excdampv_excessdamagespresvalue = Variable(index=[time,region], unit="\$million")
    excdampv_excessdamagespresvalue_ann = Variable(index=[year,region], unit="\$million")

    # convergence system for equity weighting threshold
    use_convergence = Parameter(unit="none", default=1.)
    eqwshare_shareofweighteddamages = Variable(index=[time,region], unit="none")
    eqwshare_shareofweighteddamages_ann = Variable(index=[year,region], unit="none")
    eqwshare_shareofweighteddamages_noconvergence = Variable(index=[time,region], unit="none")
    eqwshare_shareofweighteddamages_noconvergence_ann = Variable(index=[year,region], unit="none")
    eqwbound_maxshareofweighteddamages = Parameter(unit="none", default=0.99)
    eqwboundn_maxshareofweighteddamages_neighbourhood = Parameter(unit="none", default=0.9)
    eqwaux1_weighteddamages_auxiliary1 = Variable(unit="none")
    eqwaux2_weighteddamages_auxiliary2 = Variable(unit="none")

    currentdam_currentdamages = Variable(index=[time,region], unit="\$million")
    currentdam_currentdamages_ann = Variable(index=[year,region], unit="\$million")
    damshare_currentdamagesshare = Variable(index=[time,region], unit="%GDP")
    damshare_currentdamagesshare_ann = Variable(index=[year,region], unit="%GDP")
    currentdampc_percapitacurrentdamages = Variable(index=[time,region], unit="\$/person")
    currentdampc_percapitacurrentdamages_ann = Variable(index=[year,region], unit="\$/person")

    discfix_fixediscountrate = Parameter(unit="none", default=0.) # override the discount rates with something exogenous
    ###############################################

    function run_timestep(p, v, d, tt)

        # interpolate the parameters that require interpolation:
        interpolate_parameters_equityweighting(p, v, d, tt)

        if is_first(tt)
            v.tpc_totalaggregatedcosts = 0
            v.addt_gt_equityweightedimpact_discountedglobal = 0
            v.tac_totaladaptationcosts = 0
            v.te_totaleffect = 0

            v.eqwaux1_weighteddamages_auxiliary1 = 2 * (p.eqwbound_maxshareofweighteddamages - p.eqwboundn_maxshareofweighteddamages_neighbourhood)
            v.eqwaux2_weighteddamages_auxiliary2 = 4 / v.eqwaux1_weighteddamages_auxiliary1

        end

        v.df_utilitydiscountfactor[tt] = (1 + p.ptp_timepreference / 100)^(-(p.y_year[tt] - p.y_year_0))

        if p.discfix_fixediscountrate != 0.
            v.df_utilitydiscountfactor[tt] = (1 + p.discfix_fixediscountrate / 100)^(-(p.y_year[tt] - p.y_year_0))
        end


        for rr in d.region

            ## Gas Costs Accounting
            # Weighted costs (Page 23 of Hope 2009)
            v.wtct_percap_weightedcosts[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_consumption[tt, rr]^(1 - p.emuc_utilityconvexity) - (p.cons_percap_consumption[tt, rr] - p.tct_percap_totalcosts_total[tt, rr] < 0.01 * p.cons_percap_consumption_0[1] ? 0.01 * p.cons_percap_consumption_0[1] : p.cons_percap_consumption[tt, rr] - p.tct_percap_totalcosts_total[tt, rr])^(1 - p.emuc_utilityconvexity))

            # Add these into consumption
            v.eact_percap_weightedadaptationcosts[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_consumption[tt, rr]^(1 - p.emuc_utilityconvexity) - (p.cons_percap_consumption[tt, rr] - p.act_percap_adaptationcosts[tt, rr] < 0.01 * p.cons_percap_consumption_0[1] ? 0.01 * p.cons_percap_consumption_0[1] : p.cons_percap_consumption[tt, rr] - p.act_percap_adaptationcosts[tt, rr])^(1 - p.emuc_utilityconvexity))

            # Do partial weighting
            if p.equity_proportion == 0
                v.pct_percap_partiallyweighted[tt, rr] = p.tct_percap_totalcosts_total[tt, rr]
                v.wact_percap_partiallyweighted[tt, rr] = p.act_percap_adaptationcosts[tt, rr]
            else
                v.pct_percap_partiallyweighted[tt, rr] = (1 - p.equity_proportion) * p.tct_percap_totalcosts_total[tt, rr] + p.equity_proportion * v.wtct_percap_weightedcosts[tt, rr]
        v.wact_percap_partiallyweighted[tt, rr] = (1 - p.equity_proportion) * p.act_percap_adaptationcosts[tt, rr] + p.equity_proportion * v.eact_percap_weightedadaptationcosts[tt, rr]
            end

            v.pct_partiallyweighted[tt, rr] = v.pct_percap_partiallyweighted[tt, rr] * p.pop_population[tt, rr]
            v.wact_partiallyweighted[tt, rr] = v.wact_percap_partiallyweighted[tt, rr] * p.pop_population[tt, rr]

            # Discount rate calculations
            v.dr_discountrate[tt, rr] = p.ptp_timepreference + p.emuc_utilityconvexity * (p.grwnet_realizedgdpgrowth[tt, rr] - p.popgrw_populationgrowth[tt, rr])

            if p.discfix_fixediscountrate != 0.
                v.dr_discountrate[tt, rr] = p.discfix_fixediscountrate
            end


            if is_first(tt)
                v.yp_yearsperiod[TimestepIndex(1)] = p.y_year[TimestepIndex(1)] - p.y_year_0
            else
                v.yp_yearsperiod[tt] = p.y_year[tt] - p.y_year[tt - 1]
            end

            if is_first(tt)
                v.dfc_consumptiondiscountrate[TimestepIndex(1), rr] = (1 + v.dr_discountrate[TimestepIndex(1), rr] / 100)^(-v.yp_yearsperiod[TimestepIndex(1)])
            else
                v.dfc_consumptiondiscountrate[tt, rr] = v.dfc_consumptiondiscountrate[tt - 1, rr] * (1 + v.dr_discountrate[tt, rr] / 100)^(-v.yp_yearsperiod[tt])
            end

            # Discounted costs
            if p.equity_proportion == 0
                v.pcdt_partiallyweighted_discounted[tt, rr] = v.pct_partiallyweighted[tt, rr] * v.dfc_consumptiondiscountrate[tt, rr]
                v.wacdt_partiallyweighted_discounted[tt, rr] = p.act_adaptationcosts_total[tt, rr] * v.dfc_consumptiondiscountrate[tt, rr]
            else
                v.pcdt_partiallyweighted_discounted[tt, rr] = v.pct_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]
                v.wacdt_partiallyweighted_discounted[tt, rr] = v.wact_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]
            end

            v.pcdat_partiallyweighted_discountedaggregated[tt, rr] = v.pcdt_partiallyweighted_discounted[tt, rr] * p.yagg_periodspan[tt]

            # calculate the total damages due to impacts
            v.currentdam_currentdamages[tt, rr] = (p.cons_percap_aftercosts[tt, rr] - p.rcons_percap_dis[tt, rr]) * p.pop_population[tt, rr]
            v.currentdampc_percapitacurrentdamages[tt, rr] = v.currentdam_currentdamages[tt, rr] / p.pop_population[tt, rr]
            v.damshare_currentdamagesshare[tt, rr] = 100 * v.currentdampc_percapitacurrentdamages[tt, rr] / p.cons_percap_aftercosts[tt, rr]

            # if damages including GDP losses exceed current consumption levels, calculate the share for equity weighting based on the convergence system
            v.eqwshare_shareofweighteddamages_noconvergence[tt,rr] = (v.currentdam_currentdamages[tt, rr] + p.lgdp_gdploss[tt,rr]) / (p.cons_percap_aftercosts[tt, rr] * p.pop_population[tt, rr])

            if p.use_convergence == 1.
                if v.eqwshare_shareofweighteddamages_noconvergence[tt,rr] > p.eqwboundn_maxshareofweighteddamages_neighbourhood
                    v.eqwshare_shareofweighteddamages[tt,rr] = p.eqwboundn_maxshareofweighteddamages_neighbourhood - 0.5 * v.eqwaux1_weighteddamages_auxiliary1 +
                                    v.eqwaux1_weighteddamages_auxiliary1 * exp(v.eqwaux2_weighteddamages_auxiliary2 *
                                                                            (v.eqwshare_shareofweighteddamages_noconvergence[tt,rr] - p.eqwboundn_maxshareofweighteddamages_neighbourhood)) /
                                                                        (1 + exp(v.eqwaux2_weighteddamages_auxiliary2 *
                                                                                (v.eqwshare_shareofweighteddamages_noconvergence[tt,rr] - p.eqwboundn_maxshareofweighteddamages_neighbourhood)))
                    # for very large excess damages, exp(...) becomes infite and the convergence system returns NaN. In this case, simply set eqwshare to the upper bound
                    if isnan(v.eqwshare_shareofweighteddamages[tt,rr])
                        v.eqwshare_shareofweighteddamages[tt,rr] = p.eqwbound_maxshareofweighteddamages
                    end

                    v.excdam_excessdamages[tt, rr] =  max(0, v.currentdam_currentdamages[tt, rr] + p.lgdp_gdploss[tt,rr] - v.eqwshare_shareofweighteddamages[tt,rr] * p.cons_percap_aftercosts[tt, rr] * p.pop_population[tt, rr])
                else
                    v.excdam_excessdamages[tt, rr] =  0
                end
            else
                # use hard boundaries if use_convergence is not set to 1
                v.eqwshare_shareofweighteddamages[tt,rr] = min(v.eqwshare_shareofweighteddamages_noconvergence[tt,rr], p.eqwbound_maxshareofweighteddamages)
                v.excdam_excessdamages[tt, rr] =  max(0, v.currentdam_currentdamages[tt, rr] + p.lgdp_gdploss[tt,rr] - v.eqwshare_shareofweighteddamages[tt,rr] * p.cons_percap_aftercosts[tt, rr] * p.pop_population[tt, rr])
            end

            ## Equity weighted impacts (end of page 28, Hope 2009)
            if p.lossinc_includegdplosses == 0. && p.equity_proportion == 0.
                v.wit_partiallyweighted[tt, rr] = (p.cons_percap_aftercosts[tt, rr]  - p.rcons_percap_dis[tt, rr]) * p.pop_population[tt, rr]
                v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.dfc_consumptiondiscountrate[tt, rr]
            elseif p.lossinc_includegdplosses == 0. && p.equity_proportion == 1.
                v.wit_partiallyweighted[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, rr]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis[tt, rr]^(1 - p.emuc_utilityconvexity)) * p.pop_population[tt, rr]
                v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]
            elseif p.lossinc_includegdplosses == 1. && p.equity_proportion == 0.
                v.wit_partiallyweighted[tt, rr] = (p.cons_percap_aftercosts[tt, rr]  - p.rcons_percap_dis[tt, rr]) * p.pop_population[tt, rr] + p.lgdp_gdploss[tt, rr]
                v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.dfc_consumptiondiscountrate[tt, rr]
            elseif p.lossinc_includegdplosses == 1. && p.equity_proportion == 1.
                if v.excdam_excessdamages[tt, rr] == 0
                    v.wit_partiallyweighted[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, rr]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis[tt, rr]^(1 - p.emuc_utilityconvexity)) * p.pop_population[tt, rr]
                    v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]
                else
                    v.wit_partiallyweighted[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, rr]^(1 - p.emuc_utilityconvexity) - ((1 - v.eqwshare_shareofweighteddamages[tt,rr]) * p.cons_percap_aftercosts[tt, rr])^(1 - p.emuc_utilityconvexity)) * p.pop_population[tt, rr]
                    v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]  + v.excdam_excessdamages[tt, rr] *  v.dfc_consumptiondiscountrate[tt, rr]
                end
            end

            v.excdampv_excessdamagespresvalue[tt, rr] = v.excdam_excessdamages[tt, rr] *  v.dfc_consumptiondiscountrate[tt, rr]


            v.addt_equityweightedimpact_discountedaggregated[tt, rr] = v.widt_partiallyweighted_discounted[tt, rr] * p.yagg_periodspan[tt]
            v.aact_equityweightedadaptation_discountedaggregated[tt, rr] = v.wacdt_partiallyweighted_discounted[tt, rr] * p.yagg_periodspan[tt]

        end

        v.pct_g_partiallyweighted_global[tt] = sum(v.pct_partiallyweighted[tt, :])
        v.pcdt_g_partiallyweighted_discountedglobal[tt] = sum(v.pcdt_partiallyweighted_discounted[tt, :])
        v.tpc_totalaggregatedcosts = v.tpc_totalaggregatedcosts + sum(v.pcdat_partiallyweighted_discountedaggregated[tt, :])

        v.addt_gt_equityweightedimpact_discountedglobal = v.addt_gt_equityweightedimpact_discountedglobal + sum(v.addt_equityweightedimpact_discountedaggregated[tt, :])

        v.tac_totaladaptationcosts = v.tac_totaladaptationcosts + sum(v.aact_equityweightedadaptation_discountedaggregated[tt, :])

        v.td_totaldiscountedimpacts = min(v.addt_gt_equityweightedimpact_discountedglobal, p.civvalue_civilizationvalue)

        # Total effect of climate change
        v.te_totaleffect = min(v.td_totaldiscountedimpacts + v.tpc_totalaggregatedcosts + v.tac_totaladaptationcosts, p.civvalue_civilizationvalue)



        # calculate  for this specific year
        if is_first(tt)
            v.tpc_totalaggregatedcosts_ann = 0
            v.addt_gt_equityweightedimpact_discountedglobal_ann = 0
            v.tac_totaladaptationcosts_ann = 0
            v.te_totaleffect_ann = 0
            for annual_year = 2015:(gettime(tt))
                calc_equityweighting(p, v, d, tt, annual_year)
            end
        else
            for annual_year = (gettime(tt - 1) + 1):(gettime(tt))
                calc_equityweighting(p, v, d, tt, annual_year)
            end
        end

    end
end
