function buildpage(m::Model, scenario::String, use_permafrost::Bool=true, use_seaice::Bool=true, use_page09damages::Bool=false; use_page09weights::Bool=false, page09_discontinuity::Bool=false, page09_sealevelrise::Bool=false)
    # add all the components
    scenario = addrcpsspscenario(m, scenario)
    climtemp = addclimatetemperature(m, use_seaice)
    if use_permafrost
        permafrost_sibcasa = add_comp!(m, PermafrostSiBCASA)
        permafrost_jules = add_comp!(m, PermafrostJULES)
        permafrost = add_comp!(m, PermafrostTotal)
    end
    co2emit = add_comp!(m, co2emissions)
    co2cycle = addco2cycle(m, use_permafrost)
    add_comp!(m, co2forcing)
    ch4emit = add_comp!(m, ch4emissions)
    ch4cycle = addch4cycle(m, use_permafrost)
    add_comp!(m, ch4forcing)
    n2oemit = add_comp!(m, n2oemissions)
    add_comp!(m, n2ocycle)
    add_comp!(m, n2oforcing)
    lgemit = add_comp!(m, LGemissions)
    add_comp!(m, LGcycle)
    add_comp!(m, LGforcing)
    sulfemit = add_comp!(m, SulphateForcing)
    totalforcing = add_comp!(m, TotalForcing)
    if page09_sealevelrise
        add_comp!(m, PAGE09SeaLevelRise, :SeaLevelRise)
    else
        add_comp!(m, SeaLevelRise)
    end

    # Socio-Economics
    population = addpopulation(m)
    gdp = add_comp!(m, GDP)

    # Abatement Costs
    addabatementcostparameters(m, :CO2)
    addabatementcostparameters(m, :CH4)
    addabatementcostparameters(m, :N2O)
    addabatementcostparameters(m, :Lin)

    set_param!(m, :q0propmult_cutbacksatnegativecostinfinalyear, 0.8833333333333333)
    set_param!(m, :qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear, 1.1166666666666666)
    set_param!(m, :c0mult_mostnegativecostinfinalyear, 0.9333333333333334)
    set_param!(m, :curve_below_curvatureofMACcurvebelowzerocost, .5)
    set_param!(m, :curve_above_curvatureofMACcurveabovezerocost, .4)
    set_param!(m, :cross_experiencecrossoverratio, .2)
    set_param!(m, :learn_learningrate, .2)
    set_param!(m, :equity_prop_equityweightsproportion, 1)
    set_param!(m, :y_year_0, 2015)

    set_param!(m, :automult_autonomoustechchange, .65)

    addabatementcosts(m, :CO2)
    addabatementcosts(m, :CH4)
    addabatementcosts(m, :N2O)
    addabatementcosts(m, :Lin)
    add_comp!(m, TotalAbatementCosts)

    # Adaptation Costs
    adaptationcosts_sealevel = addadaptationcosts_sealevel(m)
    adaptationcosts_economic = addadaptationcosts_economic(m)
    adaptationcosts_noneconomic = addadaptationcosts_noneconomic(m)

    add_comp!(m, TotalAdaptationCosts)

    # Impacts
    slrdamages = addslrdamages(m)
    marketdamages = addmarketdamages(m, use_page09weights)
    marketdamagesburke = addmarketdamagesburke(m)
    nonmarketdamages = addnonmarketdamages(m, use_page09weights)
    if page09_discontinuity
        add_comp!(m, PAGE09Discontinuity, :Discontinuity)
    else
        add_comp!(m, Discontinuity)
    end

    # Total costs component
    add_comp!(m, TotalCosts)

    # Equity weighting and Total Costs
    equityweighting = add_comp!(m, EquityWeighting)

    # connect parameters together
    connect_param!(m, :ClimateTemperature => :fant_anthroforcing, :TotalForcing => :fant_anthroforcing)

    if use_permafrost
        permafrost_sibcasa[:rt_g] = climtemp[:rt_g_globaltemperature]
        permafrost_jules[:rt_g] = climtemp[:rt_g_globaltemperature]
        permafrost[:perm_sib_ce_co2] = permafrost_sibcasa[:perm_sib_ce_co2]
        permafrost[:perm_sib_e_co2] = permafrost_sibcasa[:perm_sib_e_co2]
        permafrost[:perm_sib_ce_ch4] = permafrost_sibcasa[:perm_sib_ce_ch4]
        permafrost[:perm_jul_ce_co2] = permafrost_jules[:perm_jul_ce_co2]
        permafrost[:perm_jul_e_co2] = permafrost_jules[:perm_jul_e_co2]
        permafrost[:perm_jul_ce_ch4] = permafrost_jules[:perm_jul_ce_ch4]
    end

    co2emit[:er_CO2emissionsgrowth] = scenario[:er_CO2emissionsgrowth]

    connect_param!(m, :CO2Cycle => :e_globalCO2emissions, :co2emissions => :e_globalCO2emissions)
    connect_param!(m, :CO2Cycle => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)
    if use_permafrost
        co2cycle[:permte_permafrostemissions] = permafrost[:perm_tot_e_co2]
    end

    connect_param!(m, :co2forcing => :c_CO2concentration, :CO2Cycle => :c_CO2concentration)

    ch4emit[:er_CH4emissionsgrowth] = scenario[:er_CH4emissionsgrowth]

    connect_param!(m, :CH4Cycle => :e_globalCH4emissions, :ch4emissions => :e_globalCH4emissions)
    connect_param!(m, :CH4Cycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :CH4Cycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)
    if use_permafrost
        ch4cycle[:permtce_permafrostemissions] = permafrost[:perm_tot_ce_ch4]
    end

    connect_param!(m, :ch4forcing => :c_CH4concentration, :CH4Cycle => :c_CH4concentration)
    connect_param!(m, :ch4forcing => :c_N2Oconcentration, :n2ocycle => :c_N2Oconcentration)

    n2oemit[:er_N2Oemissionsgrowth] = scenario[:er_N2Oemissionsgrowth]

    connect_param!(m, :n2ocycle => :e_globalN2Oemissions, :n2oemissions => :e_globalN2Oemissions)
    connect_param!(m, :n2ocycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :n2ocycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)

    connect_param!(m, :n2oforcing => :c_CH4concentration, :CH4Cycle => :c_CH4concentration)
    connect_param!(m, :n2oforcing => :c_N2Oconcentration, :n2ocycle => :c_N2Oconcentration)

    lgemit[:er_LGemissionsgrowth] = scenario[:er_LGemissionsgrowth]

    connect_param!(m, :LGcycle => :e_globalLGemissions, :LGemissions => :e_globalLGemissions)
    connect_param!(m, :LGcycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :LGcycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)

    connect_param!(m, :LGforcing => :c_LGconcentration, :LGcycle => :c_LGconcentration)

    sulfemit[:pse_sulphatevsbase] = scenario[:pse_sulphatevsbase]

    connect_param!(m, :TotalForcing => :f_CO2forcing, :co2forcing => :f_CO2forcing)
    connect_param!(m, :TotalForcing => :f_CH4forcing, :ch4forcing => :f_CH4forcing)
    connect_param!(m, :TotalForcing => :f_N2Oforcing, :n2oforcing => :f_N2Oforcing)
    connect_param!(m, :TotalForcing => :f_lineargasforcing, :LGforcing => :f_LGforcing)
    totalforcing[:exf_excessforcing] = scenario[:exf_excessforcing]
    connect_param!(m, :TotalForcing => :fs_sulfateforcing, :SulphateForcing => :fs_sulphateforcing)

    connect_param!(m, :SeaLevelRise => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)

    population[:popgrw_populationgrowth] = scenario[:popgrw_populationgrowth]

    connect_param!(m, :GDP => :pop_population, :Population => :pop_population)
    gdp[:grw_gdpgrowthrate] = scenario[:grw_gdpgrowthrate]

    for allabatement in [
        (:AbatementCostParametersCO2, :AbatementCostsCO2, :er_CO2emissionsgrowth),
        (:AbatementCostParametersCH4, :AbatementCostsCH4, :er_CH4emissionsgrowth),
        (:AbatementCostParametersN2O, :AbatementCostsN2O, :er_N2Oemissionsgrowth),
        (:AbatementCostParametersLin, :AbatementCostsLin, :er_LGemissionsgrowth)]

        abatementcostparameters, abatementcosts, er_parameter = allabatement

        connect_param!(m, abatementcostparameters => :yagg, :GDP => :yagg_periodspan)
        connect_param!(m, abatementcostparameters => :cbe_absoluteemissionreductions, abatementcosts => :cbe_absoluteemissionreductions)

        connect_param!(m, abatementcosts => :zc_zerocostemissions, abatementcostparameters => :zc_zerocostemissions)
        connect_param!(m, abatementcosts => :q0_absolutecutbacksatnegativecost, abatementcostparameters => :q0_absolutecutbacksatnegativecost)
        connect_param!(m, abatementcosts => :blo, abatementcostparameters => :blo)
        connect_param!(m, abatementcosts => :alo, abatementcostparameters => :alo)
        connect_param!(m, abatementcosts => :bhi, abatementcostparameters => :bhi)
        connect_param!(m, abatementcosts => :ahi, abatementcostparameters => :ahi)
        connect_param!(m, abatementcosts => :er_emissionsgrowth, :RCPSSPScenario => er_parameter)

    end

    connect_param!(m, :TotalAbatementCosts => :tc_totalcosts_co2, :AbatementCostsCO2 => :tc_totalcost)
    connect_param!(m, :TotalAbatementCosts => :tc_totalcosts_n2o, :AbatementCostsN2O => :tc_totalcost)
    connect_param!(m, :TotalAbatementCosts => :tc_totalcosts_ch4, :AbatementCostsCH4 => :tc_totalcost)
    connect_param!(m, :TotalAbatementCosts => :tc_totalcosts_linear, :AbatementCostsLin => :tc_totalcost)
    connect_param!(m, :TotalAbatementCosts => :pop_population, :Population => :pop_population)

    connect_param!(m, :AdaptiveCostsEconomic => :gdp, :GDP => :gdp)
    connect_param!(m, :AdaptiveCostsNonEconomic => :gdp, :GDP => :gdp)
    connect_param!(m, :AdaptiveCostsSeaLevel => :gdp, :GDP => :gdp)

    connect_param!(m, :TotalAdaptationCosts => :ac_adaptationcosts_economic, :AdaptiveCostsEconomic => :ac_adaptivecosts)
    connect_param!(m, :TotalAdaptationCosts => :ac_adaptationcosts_noneconomic, :AdaptiveCostsNonEconomic => :ac_adaptivecosts)
    connect_param!(m, :TotalAdaptationCosts => :ac_adaptationcosts_sealevelrise, :AdaptiveCostsSeaLevel => :ac_adaptivecosts)
    connect_param!(m, :TotalAdaptationCosts => :pop_population, :Population => :pop_population)

    connect_param!(m, :SLRDamages => :s_sealevel, :SeaLevelRise => :s_sealevel)
    connect_param!(m, :SLRDamages => :cons_percap_consumption, :GDP => :cons_percap_consumption)
    connect_param!(m, :SLRDamages => :cons_percap_consumption_0, :GDP => :cons_percap_consumption_0)
    connect_param!(m, :SLRDamages => :tct_per_cap_totalcostspercap, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :SLRDamages => :act_percap_adaptationcosts, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :SLRDamages => :atl_adjustedtolerablelevelofsealevelrise, :AdaptiveCostsSeaLevel => :atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :SLRDamages => :imp_actualreductionSLR, :AdaptiveCostsSeaLevel => :imp_adaptedimpacts)
    connect_param!(m, :SLRDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamages => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamages => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamages => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamages => :atl_adjustedtolerableleveloftemprise, :AdaptiveCostsEconomic => :atl_adjustedtolerablelevel, ignoreunits=true) # not required for Burke damages
    connect_param!(m, :MarketDamages => :imp_actualreduction, :AdaptiveCostsEconomic => :imp_adaptedimpacts) # not required for Burke damages
    connect_param!(m, :MarketDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamagesBurke => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamagesBurke => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamagesBurke => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamagesBurke => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :NonMarketDamages => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    if use_page09damages
        connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamages => :rgdp_per_cap_MarketRemainGDP)
        connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamages => :rcons_per_cap_MarketRemainConsumption)
    else
        connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamagesBurke => :rgdp_per_cap_MarketRemainGDP)
        connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamagesBurke => :rcons_per_cap_MarketRemainConsumption)
    end
    connect_param!(m, :NonMarketDamages => :atl_adjustedtolerableleveloftemprise, :AdaptiveCostsNonEconomic => :atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :NonMarketDamages => :imp_actualreduction, :AdaptiveCostsNonEconomic => :imp_adaptedimpacts)
    connect_param!(m, :NonMarketDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :Discontinuity => :rgdp_per_cap_NonMarketRemainGDP, :NonMarketDamages => :rgdp_per_cap_NonMarketRemainGDP)
    connect_param!(m, :Discontinuity => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)
    connect_param!(m, :Discontinuity => :rgdp_per_cap_NonMarketRemainGDP, :NonMarketDamages => :rgdp_per_cap_NonMarketRemainGDP)
    connect_param!(m, :Discontinuity => :rcons_per_cap_NonMarketRemainConsumption, :NonMarketDamages => :rcons_per_cap_NonMarketRemainConsumption)
    connect_param!(m, :Discontinuity => :isatg_saturationmodification, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :TotalCosts => :population, :Population => :pop_population)
    connect_param!(m, :TotalCosts => :period_length, :GDP => :yagg_periodspan)
    connect_param!(m, :TotalCosts => :abatement_costs_percap_peryear, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :TotalCosts => :adaptation_costs_percap_peryear, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :TotalCosts => :slr_damages_percap_peryear, :SLRDamages => :isat_per_cap_SLRImpactperCapinclSaturationandAdaptation)
    if use_page09damages
        connect_param!(m, :TotalCosts => :market_damages_percap_peryear, :MarketDamages => :isat_per_cap_ImpactperCapinclSaturationandAdaptation)
    else
        connect_param!(m, :TotalCosts => :market_damages_percap_peryear, :MarketDamagesBurke => :isat_per_cap_ImpactperCapinclSaturationandAdaptation)
    end
    connect_param!(m, :TotalCosts => :non_market_damages_percap_peryear, :NonMarketDamages => :isat_per_cap_ImpactperCapinclSaturationandAdaptation)
    connect_param!(m, :TotalCosts => :discontinuity_damages_percap_peryear, :Discontinuity => :isat_per_cap_DiscImpactperCapinclSaturation)

    connect_param!(m, :EquityWeighting => :pop_population, :Population => :pop_population)
    connect_param!(m, :EquityWeighting => :tct_percap_totalcosts_total, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :EquityWeighting => :act_adaptationcosts_total, :TotalAdaptationCosts => :act_adaptationcosts_total)
    connect_param!(m, :EquityWeighting => :act_percap_adaptationcosts, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption, :GDP => :cons_percap_consumption)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption_0, :GDP => :cons_percap_consumption_0)
    connect_param!(m, :EquityWeighting => :cons_percap_aftercosts, :SLRDamages => :cons_percap_aftercosts)
    connect_param!(m, :EquityWeighting => :rcons_percap_dis, :Discontinuity => :rcons_per_cap_DiscRemainConsumption)
    connect_param!(m, :EquityWeighting => :yagg_periodspan, :GDP => :yagg_periodspan)
    equityweighting[:grw_gdpgrowthrate] = scenario[:grw_gdpgrowthrate]
    equityweighting[:popgrw_populationgrowth] = scenario[:popgrw_populationgrowth]

    return m
end

function initpage(m::Model)
    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)
end

function getpage(scenario::String="RCP4.5 & SSP2", use_permafrost::Bool=true, use_seaice::Bool=true, use_page09damages::Bool=false; use_page09weights::Bool=false, page09_discontinuity::Bool=false, page09_sealevelrise::Bool=false)
    m = Model()
    set_dimension!(m, :time, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_dimension!(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])
    set_dimension!(m, :country, ["AFG", "ALA", "ALB", "DZA", "ASM", "AND", "AGO", "AIA", "ATA", "ATG", "ARG", "ARM", "ABW", "AUS", "AUT", "AZE"]) # TODO: Load official list from CSV

    buildpage(m, scenario, use_permafrost, use_seaice, use_page09damages; use_page09weights=use_page09weights, page09_discontinuity=page09_discontinuity, page09_sealevelrise=page09_sealevelrise)

    # next: add vector and panel example
    initpage(m)

    return m
end

get_model = getpage
