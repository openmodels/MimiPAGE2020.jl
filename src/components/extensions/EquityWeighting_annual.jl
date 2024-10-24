@defcomp EquityWeighting_annual begin

    region = Index()
    year = Index()

    # Basic information
    y_year_0 = Parameter(unit="year")
    y_year_ann = Parameter(index=[year], unit="year")

    # Impacts across all gases
    pop_population_region = Parameter(index=[time, region], unit="million person")
    pop_population_region_ann = Variable(index=[year, region], unit="million person")

    # Total and Per-Capita Abatement and Adaptation Costs
    tct_percap_totalcosts_total = Parameter(index=[time, region], unit="\$/person")
    tct_percap_totalcosts_total_ann = Variable(index=[year, region], unit="\$/person")
    act_adaptationcosts_total = Parameter(index=[time, region], unit="\$million")
    act_adaptationcosts_total_ann = Variable(index=[year, region], unit="\$million")
    act_percap_adaptationcosts = Parameter(index=[time, region], unit="\$/person")
    act_percap_adaptationcosts_ann = Variable(index=[year, region], unit="\$/person")

    # Consumption
    cons_percap_consumption_0 = Parameter(index=[region], unit="\$/person")
    cons_percap_consumption = Parameter(index=[time, region], unit="\$/person") # Called "CONS_PER_CAP"
    cons_percap_consumption_ann = Variable(index=[year, region], unit="\$/person")
    cons_percap_aftercosts = Parameter(index=[time, region], unit="\$/person")
    cons_percap_aftercosts_ann = Variable(index=[year, region], unit="\$/person")

    # Calculation of weighted costs
    emuc_utilityconvexity = Parameter(unit="none", default=1.1666666666666667)

    wtct_percap_weightedcosts_ann = Variable(index=[year, region], unit="\$/person")
    eact_percap_weightedadaptationcosts_ann = Variable(index=[year, region], unit="\$/person")
    wact_percap_partiallyweighted_ann = Variable(index=[year, region], unit="\$/person")
    wact_partiallyweighted_ann = Variable(index=[year, region], unit="\$million")

    # Amount of equity weighting variable (0, (0, 1), or 1)
    equity_proportion = Parameter(unit="fraction", default=1.0)

    pct_percap_partiallyweighted_ann = Variable(index=[year, region], unit="\$/person")
    pct_partiallyweighted_ann = Variable(index=[year, region], unit="\$million")
    pct_g_partiallyweighted_global_ann = Variable(index=[year], unit="\$million")

    # Discount rates
    ptp_timepreference = Parameter(unit="%/year", default=1.0333333333333334) # <0.1,1, 2>
    grw_gdpgrowthrate = Parameter(index=[time, region], unit="%/year")
    grw_gdpgrowthrate_ann = Variable(index=[year, region], unit="%/year")
    popgrw_populationgrowth = Parameter(index=[time, region], unit="%/year")
    popgrw_populationgrowth_ann = Variable(index=[year, region], unit="%/year")

    dr_discountrate_ann = Variable(index=[year, region], unit="%/year")
    yp_yearsperiod = Parameter(index=[time], unit="year") # defined differently from yagg
    yp_yearsperiod_ann = Variable(index=[year], unit="year")
    dfc_consumptiondiscountrate_ann = Variable(index=[year, region], unit="1/year")

    df_utilitydiscountfactor_ann = Variable(index=[year], unit="fraction")

    # Discounted costs
    pcdt_partiallyweighted_discounted_ann = Variable(index=[year, region], unit="\$million")
    pcdt_g_partiallyweighted_discountedglobal_ann = Variable(index=[year], unit="\$million")

    pcdat_partiallyweighted_discountedaggregated_ann = Variable(index=[year, region], unit="\$million")
    tpc_totalaggregatedcosts_ann = Variable(unit="\$million")

    wacdt_partiallyweighted_discounted_ann = Variable(index=[year, region], unit="\$million")

    # Equity weighted impact totals
    rcons_percap_dis_ann = Parameter(index=[year, region], unit="\$/person")

    wit_partiallyweighted_ann = Variable(index=[year, region], unit="\$million")
    widt_partiallyweighted_discounted_ann = Variable(index=[year, region], unit="\$million")

    yagg_periodspan_ann = Variable(index=[year], unit="year")

    addt_equityweightedimpact_discountedaggregated_ann = Variable(index=[year, region], unit="\$million")
    addt_gt_equityweightedimpact_discountedglobal_ann = Variable(unit="\$million")

    civvalue_civilizationvalue = Parameter(unit="\$million", default=6.1333333333333336e10) # Called "CIV_VALUE"
    td_totaldiscountedimpacts_ts = Variable(index=[time], unit="\$million") # for analysis
    td_totaldiscountedimpacts_ann = Variable(unit="\$million")
    td_totaldiscountedimpacts_ann_yr = Variable(index=[year], unit="\$million") # for analysis

    aact_equityweightedadaptation_discountedaggregated_ann = Variable(index=[year, region], unit="\$million")
    tac_totaladaptationcosts_ann = Variable(unit="\$million")

    # Final result: total effect of climate change
    te_totaleffect_ann = Variable(unit="\$million")
    te_totaleffect_ann_yr = Variable(index=[year], unit="\$million") # for analysis


    function run_timestep(p, v, d, tt)

        # interpolate the parameters that require interpolation:
        interpolate_parameters_equityweighting(p, v, d, tt)

        for rr in d.region
            # calculate  for this specific year
            if is_first(tt)
                v.tpc_totalaggregatedcosts_ann = 0
                v.addt_gt_equityweightedimpact_discountedglobal_ann = 0
                v.tac_totaladaptationcosts_ann = 0
                v.te_totaleffect_ann = 0
                for annual_year = 2015:(gettime(tt))
                    calc_equityweighting(p, v, d, tt, annual_year, rr)
                end
            else
                for annual_year = (gettime(tt - 1) + 1):(gettime(tt))
                    calc_equityweighting(p, v, d, tt, annual_year, rr)
                end
            end
        end

        v.td_totaldiscountedimpacts_ts[tt] = v.td_totaldiscountedimpacts_ann # for analysis
    end
end

function interpolate_parameters_equityweighting(p, v, d, t)

    # interpolation of parameters, see notes in run_timestep for why these parameters
    if is_first(t)
        for annual_year = 2015:(gettime(t))
            yr = annual_year - 2015 + 1
            for r in d.region

                v.pop_population_region_ann[yr, r] = p.pop_population_region[t, r]

                v.tct_percap_totalcosts_total_ann[yr, r] = p.tct_percap_totalcosts_total[t, r]
                v.act_adaptationcosts_total_ann[yr, r] = p.act_adaptationcosts_total[t, r]
                v.act_percap_adaptationcosts_ann[yr, r] = p.act_percap_adaptationcosts[t, r]

                v.cons_percap_consumption_ann[yr, r] = p.cons_percap_consumption[t, r]
                v.cons_percap_aftercosts_ann[yr, r] = p.cons_percap_aftercosts[t, r]

                v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r]
                v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r]

                v.yagg_periodspan_ann[yr] = 1 # p.yagg_periodspan[t] --- needs REVIEW

            end
        end
    else
        for annual_year = (gettime(t - 1) + 1):(gettime(t))
            yr = annual_year - 2015 + 1
            frac = annual_year - gettime(t - 1)
            fraction_timestep = frac / ((gettime(t)) - (gettime(t - 1)))

            for r in d.region
                if use_linear
                    v.pop_population_region_ann[yr, r] = p.pop_population_region[t, r] * fraction_timestep + p.pop_population_region[t - 1, r] * (1 - fraction_timestep)

                    v.tct_percap_totalcosts_total_ann[yr, r] = p.tct_percap_totalcosts_total[t, r] * fraction_timestep + p.tct_percap_totalcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_adaptationcosts_total_ann[yr, r] = p.act_adaptationcosts_total[t, r] * fraction_timestep + p.act_adaptationcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_percap_adaptationcosts_ann[yr, r] = p.act_percap_adaptationcosts[t, r] * fraction_timestep + p.act_percap_adaptationcosts[t - 1, r] * (1 - fraction_timestep)

                    v.cons_percap_consumption_ann[yr, r] = p.cons_percap_consumption[t, r] * fraction_timestep + p.cons_percap_consumption[t - 1, r] * (1 - fraction_timestep)
                    v.cons_percap_aftercosts_ann[yr, r] = p.cons_percap_aftercosts[t, r] * fraction_timestep + p.cons_percap_aftercosts[t - 1, r] * (1 - fraction_timestep)

                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)
                    v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r] * fraction_timestep + p.popgrw_populationgrowth[t - 1, r] * (1 - fraction_timestep)
                elseif use_logburke
                    ## fully linear (partially because everything except for pop_population_region causes imaginary numbers (due to negative numbers)).
                    # linear
                    v.tct_percap_totalcosts_total_ann[yr, r] = p.tct_percap_totalcosts_total[t, r] * fraction_timestep + p.tct_percap_totalcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_adaptationcosts_total_ann[yr, r] = p.act_adaptationcosts_total[t, r] * fraction_timestep + p.act_adaptationcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_percap_adaptationcosts_ann[yr, r] = p.act_percap_adaptationcosts[t, r] * fraction_timestep + p.act_percap_adaptationcosts[t - 1, r] * (1 - fraction_timestep)

                    v.cons_percap_consumption_ann[yr, r] = p.cons_percap_consumption[t, r] * fraction_timestep + p.cons_percap_consumption[t - 1, r] * (1 - fraction_timestep)
                    v.cons_percap_aftercosts_ann[yr, r] = p.cons_percap_aftercosts[t, r] * fraction_timestep + p.cons_percap_aftercosts[t - 1, r] * (1 - fraction_timestep)

                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)
                    v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r] * fraction_timestep + p.popgrw_populationgrowth[t - 1, r] * (1 - fraction_timestep)

                    v.pop_population_region_ann[yr, r] = p.pop_population_region[t, r] * fraction_timestep + p.pop_population_region[t - 1, r] * (1 - fraction_timestep)

                elseif use_logpopulation
                    # linear
                    v.tct_percap_totalcosts_total_ann[yr, r] = p.tct_percap_totalcosts_total[t, r] * fraction_timestep + p.tct_percap_totalcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_adaptationcosts_total_ann[yr, r] = p.act_adaptationcosts_total[t, r] * fraction_timestep + p.act_adaptationcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_percap_adaptationcosts_ann[yr, r] = p.act_percap_adaptationcosts[t, r] * fraction_timestep + p.act_percap_adaptationcosts[t - 1, r] * (1 - fraction_timestep)

                    v.cons_percap_consumption_ann[yr, r] = p.cons_percap_consumption[t, r] * fraction_timestep + p.cons_percap_consumption[t - 1, r] * (1 - fraction_timestep)
                    v.cons_percap_aftercosts_ann[yr, r] = p.cons_percap_aftercosts[t, r] * fraction_timestep + p.cons_percap_aftercosts[t - 1, r] * (1 - fraction_timestep)

                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)
                    v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r] * fraction_timestep + p.popgrw_populationgrowth[t - 1, r] * (1 - fraction_timestep)

                    # log
                    v.pop_population_region_ann[yr, r] = p.pop_population_region[t, r]^fraction_timestep * p.pop_population_region[t - 1, r]^(1 - fraction_timestep)
                elseif use_logwherepossible
                    # linear
                    v.tct_percap_totalcosts_total_ann[yr, r] = p.tct_percap_totalcosts_total[t, r] * fraction_timestep + p.tct_percap_totalcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_adaptationcosts_total_ann[yr, r] = p.act_adaptationcosts_total[t, r] * fraction_timestep + p.act_adaptationcosts_total[t - 1, r] * (1 - fraction_timestep)
                    v.act_percap_adaptationcosts_ann[yr, r] = p.act_percap_adaptationcosts[t, r] * fraction_timestep + p.act_percap_adaptationcosts[t - 1, r] * (1 - fraction_timestep)

                    v.cons_percap_consumption_ann[yr, r] = p.cons_percap_consumption[t, r] * fraction_timestep + p.cons_percap_consumption[t - 1, r] * (1 - fraction_timestep)
                    v.cons_percap_aftercosts_ann[yr, r] = p.cons_percap_aftercosts[t, r] * fraction_timestep + p.cons_percap_aftercosts[t - 1, r] * (1 - fraction_timestep)

                    v.grw_gdpgrowthrate_ann[yr, r] = p.grw_gdpgrowthrate[t, r] * fraction_timestep + p.grw_gdpgrowthrate[t - 1, r] * (1 - fraction_timestep)
                    v.popgrw_populationgrowth_ann[yr, r] = p.popgrw_populationgrowth[t, r] * fraction_timestep + p.popgrw_populationgrowth[t - 1, r] * (1 - fraction_timestep)

                    # log
                    v.pop_population_region_ann[yr, r] = p.pop_population_region[t, r]^fraction_timestep * p.pop_population_region[t - 1, r]^(1 - fraction_timestep)
                else
                    error("NO INTERPOLATION METHOD SELECTED! Specify linear or logarithmic interpolation.")
                end

                v.yagg_periodspan_ann[yr] = 1
            end
        end
    end
end

function calc_equityweighting(p, v, d, t, annual_year, r)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    v.df_utilitydiscountfactor_ann[yr] = (1 + p.ptp_timepreference / 100)^(-(p.y_year_ann[yr] - p.y_year_0))

    for rr in d.region
        ## Gas Costs Accounting
        # Weighted costs (Page 23 of Hope 2009)
        v.wtct_percap_weightedcosts_ann[yr, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (v.cons_percap_consumption_ann[yr, rr]^(1 - p.emuc_utilityconvexity) - (v.cons_percap_consumption_ann[yr, rr] - v.tct_percap_totalcosts_total_ann[yr, rr])^(1 - p.emuc_utilityconvexity))

        # Add these into consumption
        v.eact_percap_weightedadaptationcosts_ann[yr, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (v.cons_percap_consumption_ann[yr, rr]^(1 - p.emuc_utilityconvexity) - (v.cons_percap_consumption_ann[yr, rr] - v.act_percap_adaptationcosts_ann[yr, rr])^(1 - p.emuc_utilityconvexity))

        # Do partial weighting
        if p.equity_proportion == 0
            v.pct_percap_partiallyweighted_ann[yr, rr] = v.tct_percap_totalcosts_total_ann[yr, rr]
            v.wact_percap_partiallyweighted_ann[yr, rr] = v.act_percap_adaptationcosts_ann[yr, rr]
        else
            v.pct_percap_partiallyweighted_ann[yr, rr] = (1 - p.equity_proportion) * v.tct_percap_totalcosts_total_ann[yr, rr] + p.equity_proportion * v.wtct_percap_weightedcosts_ann[yr, rr]
            v.wact_percap_partiallyweighted_ann[yr, rr] = (1 - p.equity_proportion) * v.act_percap_adaptationcosts_ann[yr, rr] + p.equity_proportion * v.eact_percap_weightedadaptationcosts_ann[yr, rr]
        end

        v.pct_partiallyweighted_ann[yr, rr] = v.pct_percap_partiallyweighted_ann[yr, rr] * v.pop_population_region_ann[yr, rr]
        v.wact_partiallyweighted_ann[yr, rr] = v.wact_percap_partiallyweighted_ann[yr, rr] * v.pop_population_region_ann[yr, rr]

        # Discount rate calculations
        v.dr_discountrate_ann[yr, rr] = p.ptp_timepreference + p.emuc_utilityconvexity * (v.grw_gdpgrowthrate_ann[yr, rr] - v.popgrw_populationgrowth_ann[yr, rr])
        v.yp_yearsperiod_ann[yr] = 1 # every timestep is 1 year long.
        if yr == 1
            v.dfc_consumptiondiscountrate_ann[yr, rr] = (1 + v.dr_discountrate_ann[yr, rr] / 100)^(-p.yp_yearsperiod[TimestepIndex(1)])
        else
            v.dfc_consumptiondiscountrate_ann[yr, rr] = v.dfc_consumptiondiscountrate_ann[yr - 1, rr] * (1 + v.dr_discountrate_ann[yr, rr] / 100)^(-v.yp_yearsperiod_ann[yr])
        end

        # Discounted costs
        if p.equity_proportion == 0
            v.pcdt_partiallyweighted_discounted_ann[yr, rr] = v.pct_partiallyweighted_ann[yr, rr] * v.dfc_consumptiondiscountrate_ann[yr, rr]
            v.wacdt_partiallyweighted_discounted_ann[yr, rr] = v.act_adaptationcosts_total_ann[yr, rr] * v.dfc_consumptiondiscountrate_ann[yr, rr]
            v.wit_partiallyweighted_ann[yr, rr] = (v.cons_percap_aftercosts_ann[yr, rr] - p.rcons_percap_dis_ann[yr, rr]) * v.pop_population_region_ann[yr, rr] # equivalent to emuc = 0
            v.widt_partiallyweighted_discounted_ann[yr, rr] = v.wit_partiallyweighted_ann[yr, rr] * v.dfc_consumptiondiscountrate_ann[yr] # apply Ramsey discounting
        else
            v.pcdt_partiallyweighted_discounted_ann[yr, rr] = v.pct_partiallyweighted_ann[yr, rr] * v.df_utilitydiscountfactor_ann[yr]
            v.wacdt_partiallyweighted_discounted_ann[yr, rr] = v.wact_partiallyweighted_ann[yr, rr] * v.df_utilitydiscountfactor_ann[yr]
            ## Equity weighted impacts (end of page 28, Hope 2009)
            v.wit_partiallyweighted_ann[yr, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (v.cons_percap_aftercosts_ann[yr, rr]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis_ann[yr, rr]^(1 - p.emuc_utilityconvexity)) * v.pop_population_region_ann[yr, rr]
            v.widt_partiallyweighted_discounted_ann[yr, rr] = v.wit_partiallyweighted_ann[yr, rr] * v.df_utilitydiscountfactor_ann[yr]
        end
        v.pcdat_partiallyweighted_discountedaggregated_ann[yr, rr] = v.pcdt_partiallyweighted_discounted_ann[yr, rr] * v.yagg_periodspan_ann[yr]

        v.addt_equityweightedimpact_discountedaggregated_ann[yr, rr] = v.widt_partiallyweighted_discounted_ann[yr, rr] * v.yagg_periodspan_ann[yr]
        v.aact_equityweightedadaptation_discountedaggregated_ann[yr, rr] = v.wacdt_partiallyweighted_discounted_ann[yr, rr] * v.yagg_periodspan_ann[yr]
    end


    # some new annual variables that sum over the regions
    if isequal(r, 8)
        v.pct_g_partiallyweighted_global_ann[yr] = sum(v.pct_partiallyweighted_ann[yr, :])
        v.pcdt_g_partiallyweighted_discountedglobal_ann[yr] = sum(v.pcdt_partiallyweighted_discounted_ann[yr, :])

        v.tpc_totalaggregatedcosts_ann = v.tpc_totalaggregatedcosts_ann + sum(v.pcdat_partiallyweighted_discountedaggregated_ann[yr, :])

        v.addt_gt_equityweightedimpact_discountedglobal_ann = v.addt_gt_equityweightedimpact_discountedglobal_ann + sum(v.addt_equityweightedimpact_discountedaggregated_ann[yr, :])

        v.tac_totaladaptationcosts_ann = v.tac_totaladaptationcosts_ann + sum(v.aact_equityweightedadaptation_discountedaggregated_ann[yr, :])

        v.td_totaldiscountedimpacts_ann = min(v.addt_gt_equityweightedimpact_discountedglobal_ann, p.civvalue_civilizationvalue)

        # Total effect of climate change
        v.te_totaleffect_ann = min(v.td_totaldiscountedimpacts_ann + v.tpc_totalaggregatedcosts_ann + v.tac_totaladaptationcosts_ann, p.civvalue_civilizationvalue)

        # for analysis / debugging / code analysis
        v.td_totaldiscountedimpacts_ann_yr[yr] = v.td_totaldiscountedimpacts_ann
        v.te_totaleffect_ann_yr[yr] = v.te_totaleffect_ann
    end
end
