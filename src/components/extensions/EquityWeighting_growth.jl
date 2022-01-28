@defcomp EquityWeighting begin
    region = Index()

    # Basic information
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")

    # Impacts across all gases
    pop_population = Parameter(index=[time, region], unit="million person")

    # Consumption
    cons_percap_consumption_0 = Parameter(index=[region], unit="\$/person")
    cons_percap_aftercosts = Parameter(index=[time, region], unit="\$/person")

    # Calculation of weighted costs
    emuc_utilityconvexity = Parameter(unit="none", default=1.1666666666666667)

    # Amount of equity weighting variable (0, (0, 1), or 1)
    equity_proportion = Parameter(unit="fraction", default=1.0)

    # Discount rates
    ptp_timepreference = Parameter(unit="%/year", default=1.0333333333333334) # <0.1,1, 2>
    popgrw_populationgrowth = Parameter(index=[time, region], unit="%/year")

    dr_discountrate = Variable(index=[time, region], unit="%/year")
    dfc_consumptiondiscountrate = Parameter(index=[time, region], unit="1/year")

    df_utilitydiscountfactor = Variable(index=[time], unit="fraction")

    # Discounted costs
    tpc_totalaggregatedcosts = Parameter(unit="\$million")

    # Equity weighted impact totals
    rcons_percap_dis = Parameter(index=[time, region], unit="\$/person")

    wit_partiallyweighted = Variable(index=[time, region], unit="\$million")
    widt_partiallyweighted_discounted = Variable(index=[time, region], unit="\$million")

    yagg_periodspan = Parameter(index=[time], unit="year")

    addt_equityweightedimpact_discountedaggregated = Variable(index=[time, region], unit="\$million")
    addt_gt_equityweightedimpact_discountedglobal = Variable(unit="\$million")

    civvalue_civilizationvalue = Parameter(unit="\$million", default=6.1333333333333336e10) # Called "CIV_VALUE"
    td_totaldiscountedimpacts = Variable(unit="\$million")

    tac_totaladaptationcosts = Parameter(unit="\$million")

    # Final result: total effect of climate change
    te_totaleffect = Variable(unit="\$million")

    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    # additional paramters and variables for growth effects and boundaries
    grwnet_realizedgdpgrowth = Parameter(index=[time, region], unit="%/year")
    lgdp_gdploss =  Parameter(index=[time, region], unit="\$M")
    lossinc_includegdplosses = Parameter(unit="none", default=1.)
    excdam_excessdamages = Variable(index=[time,region], unit="\$million")
    excdampv_excessdamagespresvalue = Variable(index=[time,region], unit="\$million")

    # convergence system for equity weighting threshold
    use_convergence = Parameter(unit="none", default=1.)
    eqwshare_shareofweighteddamages = Variable(index=[time,region], unit="none")
    eqwshare_shareofweighteddamages_noconvergence = Variable(index=[time,region], unit="none")
    eqwbound_maxshareofweighteddamages = Parameter(unit="none", default=0.99)
    eqwboundn_maxshareofweighteddamages_neighbourhood = Parameter(unit="none", default=0.9)
    eqwaux1_weighteddamages_auxiliary1 = Variable(unit="none")
    eqwaux2_weighteddamages_auxiliary2 = Variable(unit="none")

    currentdam_currentdamages = Variable(index=[time,region], unit="\$million")
    damshare_currentdamagesshare = Variable(index=[time,region], unit="%GDP")
    currentdampc_percapitacurrentdamages = Variable(index=[time,region], unit="\$/person")

    discfix_fixediscountrate = Parameter(unit="none", default=0.) # override the discount rates with something exogenous
    ###############################################

    function run_timestep(p, v, d, tt)
        if is_first(tt)
            v.eqwaux1_weighteddamages_auxiliary1 = 2 * (p.eqwbound_maxshareofweighteddamages - p.eqwboundn_maxshareofweighteddamages_neighbourhood)
            v.eqwaux2_weighteddamages_auxiliary2 = 4 / v.eqwaux1_weighteddamages_auxiliary1
        end

        if p.discfix_fixediscountrate != 0.
            v.df_utilitydiscountfactor[tt] = (1 + p.discfix_fixediscountrate / 100)^(-(p.y_year[tt] - p.y_year_0))
        end


        for rr in d.region
            # Discount rate calculations
            v.dr_discountrate[tt, rr] = p.ptp_timepreference + p.emuc_utilityconvexity * (p.grwnet_realizedgdpgrowth[tt, rr] - p.popgrw_populationgrowth[tt, rr])

            if p.discfix_fixediscountrate != 0.
                v.dr_discountrate[tt, rr] = p.discfix_fixediscountrate
            end

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
                v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * p.dfc_consumptiondiscountrate[tt, rr]
            elseif p.lossinc_includegdplosses == 0. && p.equity_proportion == 1.
                v.wit_partiallyweighted[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, rr]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis[tt, rr]^(1 - p.emuc_utilityconvexity)) * p.pop_population[tt, rr]
                v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]
            elseif p.lossinc_includegdplosses == 1. && p.equity_proportion == 0.
                v.wit_partiallyweighted[tt, rr] = (p.cons_percap_aftercosts[tt, rr]  - p.rcons_percap_dis[tt, rr]) * p.pop_population[tt, rr] + p.lgdp_gdploss[tt, rr]
                v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * p.dfc_consumptiondiscountrate[tt, rr]
            elseif p.lossinc_includegdplosses == 1. && p.equity_proportion == 1.
                if v.excdam_excessdamages[tt, rr] == 0
                    v.wit_partiallyweighted[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, rr]^(1 - p.emuc_utilityconvexity) - p.rcons_percap_dis[tt, rr]^(1 - p.emuc_utilityconvexity)) * p.pop_population[tt, rr]
                    v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]
                else
                    v.wit_partiallyweighted[tt, rr] = ((p.cons_percap_consumption_0[1]^p.emuc_utilityconvexity) / (1 - p.emuc_utilityconvexity)) * (p.cons_percap_aftercosts[tt, rr]^(1 - p.emuc_utilityconvexity) - ((1 - v.eqwshare_shareofweighteddamages[tt,rr]) * p.cons_percap_aftercosts[tt, rr])^(1 - p.emuc_utilityconvexity)) * p.pop_population[tt, rr]
                    v.widt_partiallyweighted_discounted[tt, rr] = v.wit_partiallyweighted[tt, rr] * v.df_utilitydiscountfactor[tt]  + v.excdam_excessdamages[tt, rr] *  p.dfc_consumptiondiscountrate[tt, rr]
                end
            end

            v.excdampv_excessdamagespresvalue[tt, rr] = v.excdam_excessdamages[tt, rr] *  p.dfc_consumptiondiscountrate[tt, rr]

            v.addt_equityweightedimpact_discountedaggregated[tt, rr] = v.widt_partiallyweighted_discounted[tt, rr] * p.yagg_periodspan[tt]
        end

        v.addt_gt_equityweightedimpact_discountedglobal = v.addt_gt_equityweightedimpact_discountedglobal + sum(v.addt_equityweightedimpact_discountedaggregated[tt, :])
        v.td_totaldiscountedimpacts = min(v.addt_gt_equityweightedimpact_discountedglobal, p.civvalue_civilizationvalue)

        # Total effect of climate change
        v.te_totaleffect = min(v.td_totaldiscountedimpacts + p.tpc_totalaggregatedcosts + p.tac_totaladaptationcosts, p.civvalue_civilizationvalue)
    end
end
