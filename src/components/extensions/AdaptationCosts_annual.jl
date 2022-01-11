@defcomp AdaptationCosts_annual begin
    region = Index()
    year = Index()

    y_year_0 = Parameter(unit="year")
    y_year_lssp = Parameter(unit="year", default=2100.)
    y_year_ann = Parameter(index=[year], unit="year")
    gdp_ann = Parameter(index=[year, region], unit="\$M")
    cf_costregional = Parameter(index=[region], unit="none") # first value should be 1.

    automult_autonomoustechchange = Parameter(unit="none", default=.65)
    impmax_maximumadaptivecapacity = Parameter(index=[region], unit="driver")
    # tolerability parameters
    plateau_increaseintolerableplateaufromadaptation = Parameter(index=[region], unit="driver")
    pstart_startdateofadaptpolicy = Parameter(index=[region], unit="year")
    pyears_yearstilfulleffect = Parameter(index=[region], unit="year")
    impred_eventualpercentreduction = Parameter(index=[region], unit="%")
    istart_startdate = Parameter(index=[region], unit="year")
    iyears_yearstilfulleffect = Parameter(index=[region], unit="year")

    cp_costplateau_eu = Parameter(unit="%GDP/driver")
    ci_costimpact_eu = Parameter(unit="%GDP/%driver")

    atl_adjustedtolerablelevel_ann = Variable(index=[year, region])
    imp_adaptedimpacts_ann = Variable(index=[year, region], unit="%")

    # Mostly for debugging
    autofac_autonomoustechchangefraction_ann = Variable(index=[year], unit="none")
    acp_adaptivecostplateau_ann = Variable(index=[year, region], unit="\$million")
    aci_adaptivecostimpact_ann = Variable(index=[year, region], unit="\$million")

    ac_adaptivecosts_ann = Variable(index=[year, region], unit="\$million")

    function run_timestep(p, v, d, tt)
        # calculate  for this specific year
        if is_first(tt)
            for annual_year = 2015:(gettime(tt))
                calc_adaptationcosts(p, v, d, tt, annual_year)
            end
        else
            for annual_year = (gettime(tt - 1) + 1):(gettime(tt))
                calc_adaptationcosts(p, v, d, tt, annual_year)
            end
        end
    end
end

function calc_adaptationcosts(p, v, d, tt, annual_year)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    # Hope (2009), p. 21, equation -5
    auto_autonomoustechchangepercent = (1 - p.automult_autonomoustechchange^(1 / (p.y_year_lssp - p.y_year_0))) * 100 # % per year
    v.autofac_autonomoustechchangefraction_ann[yr] = (1 - auto_autonomoustechchangepercent / 100)^(p.y_year_ann[yr] - p.y_year_0) # Varies by year

    for rr in d.region
        # calculate adjusted tolerable level and max impact based on adaptation policy
        if (p.y_year_ann[yr] - p.pstart_startdateofadaptpolicy[rr]) < 0
            v.atl_adjustedtolerablelevel_ann[yr,rr] = 0
        elseif ((p.y_year_ann[yr] - p.pstart_startdateofadaptpolicy[rr]) / p.pyears_yearstilfulleffect[rr]) < 1.
            v.atl_adjustedtolerablelevel_ann[yr,rr] =
                ((p.y_year_ann[yr] - p.pstart_startdateofadaptpolicy[rr]) / p.pyears_yearstilfulleffect[rr]) *
                p.plateau_increaseintolerableplateaufromadaptation[rr]
        else
            v.atl_adjustedtolerablelevel_ann[yr,rr] = p.plateau_increaseintolerableplateaufromadaptation[rr]
        end

        if (p.y_year_ann[yr] - p.istart_startdate[rr]) < 0
            v.imp_adaptedimpacts_ann[yr,rr] = 0
        elseif ((p.y_year_ann[yr] - p.istart_startdate[rr]) / p.iyears_yearstilfulleffect[rr]) < 1
            v.imp_adaptedimpacts_ann[yr,rr] =
                (p.y_year_ann[yr] - p.istart_startdate[rr]) / p.iyears_yearstilfulleffect[rr] *
                p.impred_eventualpercentreduction[rr]
        else
            v.imp_adaptedimpacts_ann[yr,rr] = p.impred_eventualpercentreduction[rr]
        end

        # Hope (2009), p. 25, equations 1-2
        cp_costplateau_regional = p.cp_costplateau_eu * p.cf_costregional[rr]
        ci_costimpact_regional = p.ci_costimpact_eu * p.cf_costregional[rr]

        # Hope (2009), p. 25, equations 3-4
        v.acp_adaptivecostplateau_ann[yr, rr] = v.atl_adjustedtolerablelevel_ann[yr, rr] * cp_costplateau_regional * p.gdp_ann[yr, rr] * v.autofac_autonomoustechchangefraction_ann[yr] / 100
        v.aci_adaptivecostimpact_ann[yr, rr] = v.imp_adaptedimpacts_ann[yr, rr] * ci_costimpact_regional * p.gdp_ann[yr, rr] * p.impmax_maximumadaptivecapacity[rr] * v.autofac_autonomoustechchangefraction_ann[yr] / 100

        # Hope (2009), p. 25, equation 5
        v.ac_adaptivecosts_ann[yr, rr] = v.acp_adaptivecostplateau_ann[yr, rr] + v.aci_adaptivecostimpact_ann[yr, rr]
    end
end