using Mimi

Base.include(Main, "utils/load_parameters.jl")
Base.include(Main, "utils/mctools.jl")

Base.include(Main, "compute_scc.jl")

Base.include(Main, "components/RCPSSPScenario.jl")
Base.include(Main, "components/CO2emissions.jl")
Base.include(Main, "components/CO2cycle.jl")
Base.include(Main, "components/CO2forcing.jl")
Base.include(Main, "components/CH4emissions.jl")
Base.include(Main, "components/CH4cycle.jl")
Base.include(Main, "components/CH4forcing.jl")
Base.include(Main, "components/N2Oemissions.jl")
Base.include(Main, "components/N2Ocycle.jl")
Base.include(Main, "components/N2Oforcing.jl")
Base.include(Main, "components/LGemissions.jl")
Base.include(Main, "components/LGcycle.jl")
Base.include(Main, "components/LGforcing.jl")
Base.include(Main, "components/SulphateForcing.jl")
Base.include(Main, "components/TotalForcing.jl")
Base.include(Main, "components/ClimateTemperature.jl")
Base.include(Main, "components/SeaLevelRise.jl")
Base.include(Main, "components/GDP.jl")
Base.include(Main, "components/MarketDamages.jl")
Base.include(Main, "components/MarketDamagesBurke.jl")
Base.include(Main, "components/MarketDamagesRegion.jl")
Base.include(Main, "components/MarketDamagesRegionBayes.jl")
Base.include(Main, "components/NonMarketDamages.jl")
Base.include(Main, "components/Discontinuity.jl")
Base.include(Main, "components/AdaptationCosts.jl")
Base.include(Main, "components/SLRDamages.jl")
Base.include(Main, "components/AbatementCostParameters.jl")
Base.include(Main, "components/AbatementCosts.jl")
Base.include(Main, "components/TotalAbatementCosts.jl")
Base.include(Main, "components/TotalAdaptationCosts.jl")
Base.include(Main, "components/Population.jl")
Base.include(Main, "components/EquityWeighting.jl")

function buildpage(m::Model, scenario::String, use_permafrost::Bool=true)

    #add all the components
    scenario = addrcpsspscenario(m, scenario)
    co2emit = add_comp!(m, co2emissions)
    addco2cycle(m, use_permafrost)
    add_comp!(m, co2forcing)
    ch4emit = add_comp!(m, ch4emissions)
    addch4cycle(m, use_permafrost)
    add_comp!(m, ch4forcing)
    n2oemit = add_comp!(m, n2oemissions)
    add_comp!(m, n2ocycle)
    add_comp!(m, n2oforcing)
    lgemit = add_comp!(m, LGemissions)
    add_comp!(m, LGcycle)
    add_comp!(m, LGforcing)
    sulfemit = add_comp!(m, SulphateForcing)
    totalforcing = add_comp!(m, TotalForcing)
    add_comp!(m, ClimateTemperature)
    add_comp!(m, SeaLevelRise)

    #Socio-Economics
    population = addpopulation(m)
    gdp = add_comp!(m, GDP)

    #Abatement Costs
    abatementcostparameters_CO2 = addabatementcostparameters(m, :CO2)
    abatementcostparameters_CH4 = addabatementcostparameters(m, :CH4)
    abatementcostparameters_N2O = addabatementcostparameters(m, :N2O)
    abatementcostparameters_Lin = addabatementcostparameters(m, :Lin)

    abatementcosts_CO2 = addabatementcosts(m, :CO2)
    abatementcosts_CH4 = addabatementcosts(m, :CH4)
    abatementcosts_N2O = addabatementcosts(m, :N2O)
    abatementcosts_Lin = addabatementcosts(m, :Lin)
    add_comp!(m, TotalAbatementCosts)

    #Adaptation Costs
    adaptationcosts_sealevel = addadaptationcosts_sealevel(m)
    adaptationcosts_economic = addadaptationcosts_economic(m)
    adaptationcosts_noneconomic = addadaptationcosts_noneconomic(m)
    add_comp!(m, TotalAdaptationCosts)

    # Impacts
    slrdamages = addslrdamages(m)
    marketdamages = addmarketdamages(m)
    marketdamagesburke = addmarketdamagesburke(m)
    marketdamagesregion = addmarketdamagesregion(m)
    marketdamagesregionbayes = addmarketdamagesregionbayes(m)
    nonmarketdamages = addnonmarketdamages(m)
    add_comp!(m, Discontinuity)

    #Equity weighting and Total Costs
    equityweighting = add_comp!(m, EquityWeighting)

    #connect parameters together
    co2emit[:er_CO2emissionsgrowth] = scenario[:er_CO2emissionsgrowth]

    connect_param!(m, :CO2Cycle => :e_globalCO2emissions, :co2emissions => :e_globalCO2emissions)
    connect_param!(m, :CO2Cycle => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)

    connect_param!(m, :co2forcing => :c_CO2concentration, :CO2Cycle => :c_CO2concentration)

    ch4emit[:er_CH4emissionsgrowth] = scenario[:er_CH4emissionsgrowth]

    connect_param!(m, :CH4Cycle => :e_globalCH4emissions, :ch4emissions => :e_globalCH4emissions)
    connect_param!(m, :CH4Cycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :CH4Cycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)

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

    connect_param!(m, :ClimateTemperature => :ft_totalforcing, :TotalForcing => :ft_totalforcing)
    connect_param!(m, :ClimateTemperature => :fs_sulfateforcing, :SulphateForcing => :fs_sulphateforcing)

    connect_param!(m, :SeaLevelRise => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)

    population[:popgrw_populationgrowth] = scenario[:popgrw_populationgrowth]

    connect_param!(m, :GDP => :pop_population, :Population => :pop_population)
    gdp[:grw_gdpgrowthrate] = scenario[:grw_gdpgrowthrate]
    if @isdefined modelspec_master
        if modelspec_master == "PAGE09"
            connect_param!(m, :GDP => :isat_ImpactinclSaturationandAdaptation, :MarketDamages => :isat_ImpactinclSaturationandAdaptation)
        elseif modelspec_master == "Burke"
            connect_param!(m, :GDP => :isat_ImpactinclSaturationandAdaptation, :MarketDamagesBurke => :isat_ImpactinclSaturationandAdaptation)
        elseif modelspec_master == "Region"
            connect_param!(m, :GDP => :isat_ImpactinclSaturationandAdaptation, :MarketDamagesRegion => :isat_ImpactinclSaturationandAdaptation)
        elseif modelspec_master == "RegionBayes"
            connect_param!(m, :GDP => :isat_ImpactinclSaturationandAdaptation, :MarketDamagesRegionBayes => :isat_ImpactinclSaturationandAdaptation)
        else
            error("The modelspec_master parameter must be either Burke, Region, RegionBayes or PAGE09. Please adjust the parameter")
        end
    else # RegionBayes as default if the master parameter was not defined
        connect_param!(m, :GDP => :isat_ImpactinclSaturationandAdaptation, :MarketDamagesRegionBayes => :isat_ImpactinclSaturationandAdaptation)
    end

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
    connect_param!(m, :SLRDamages => :tct_per_cap_totalcostspercap, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :SLRDamages => :act_percap_adaptationcosts, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :SLRDamages => :atl_adjustedtolerablelevelofsealevelrise, :AdaptiveCostsSeaLevel => :atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :SLRDamages => :imp_actualreductionSLR, :AdaptiveCostsSeaLevel => :imp_adaptedimpacts)
    connect_param!(m, :SLRDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamages => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamages => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamages => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamages => :atl_adjustedtolerableleveloftemprise, :AdaptiveCostsEconomic => :atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :MarketDamages => :imp_actualreduction, :AdaptiveCostsEconomic => :imp_adaptedimpacts)
    connect_param!(m, :MarketDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamagesBurke => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamagesBurke => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamagesBurke => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamagesBurke => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamagesRegion => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamagesRegion => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamagesRegion => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamagesRegion => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamagesRegionBayes => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamagesRegionBayes => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamagesRegionBayes => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamagesRegionBayes => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :NonMarketDamages => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    if @isdefined modelspec_master
        if modelspec_master == "PAGE09"
            connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamages => :rgdp_per_cap_MarketRemainGDP)
            connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamages => :rcons_per_cap_MarketRemainConsumption)
        elseif modelspec_master == "Burke"
            connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamagesBurke => :rgdp_per_cap_MarketRemainGDP)
            connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamagesBurke => :rcons_per_cap_MarketRemainConsumption)
        elseif modelspec_master == "Region"
            connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamagesRegion => :rgdp_per_cap_MarketRemainGDP)
            connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamagesRegion => :rcons_per_cap_MarketRemainConsumption)
        elseif modelspec_master == "RegionBayes"
            connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamagesRegionBayes => :rgdp_per_cap_MarketRemainGDP)
            connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamagesRegionBayes => :rcons_per_cap_MarketRemainConsumption)
        end
    else # use RegionBayes as default if master parameter is not set
        connect_param!(m, :NonMarketDamages => :rgdp_per_cap_MarketRemainGDP, :MarketDamagesRegion => :rgdp_per_cap_MarketRemainGDP)
        connect_param!(m, :NonMarketDamages => :rcons_per_cap_MarketRemainConsumption, :MarketDamagesRegion => :rcons_per_cap_MarketRemainConsumption)
    end

    connect_param!(m, :NonMarketDamages =>:atl_adjustedtolerableleveloftemprise, :AdaptiveCostsNonEconomic =>:atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :NonMarketDamages => :imp_actualreduction, :AdaptiveCostsNonEconomic => :imp_adaptedimpacts)
    connect_param!(m, :NonMarketDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :Discontinuity => :rgdp_per_cap_NonMarketRemainGDP, :NonMarketDamages => :rgdp_per_cap_NonMarketRemainGDP)
    connect_param!(m, :Discontinuity => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)
    connect_param!(m, :Discontinuity => :rgdp_per_cap_NonMarketRemainGDP, :NonMarketDamages => :rgdp_per_cap_NonMarketRemainGDP)
    connect_param!(m, :Discontinuity => :rcons_per_cap_NonMarketRemainConsumption, :NonMarketDamages => :rcons_per_cap_NonMarketRemainConsumption)
    connect_param!(m, :Discontinuity => :isatg_saturationmodification, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :EquityWeighting => :pop_population, :Population => :pop_population)
    connect_param!(m, :EquityWeighting => :tct_percap_totalcosts_total, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :EquityWeighting => :act_adaptationcosts_total, :TotalAdaptationCosts => :act_adaptationcosts_total)
    connect_param!(m, :EquityWeighting => :act_percap_adaptationcosts, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption, :GDP => :cons_percap_consumption)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption_0, :GDP => :cons_percap_consumption_0)
    connect_param!(m, :EquityWeighting => :grwnet_realizedgdpgrowth, :GDP => :grwnet_realizedgdpgrowth)
#    connect_param!(m, :EquityWeighting => :lgdp_gdploss, :GDP => :lgdp_gdploss)
    connect_param!(m, :EquityWeighting => :cons_percap_aftercosts, :SLRDamages => :cons_percap_aftercosts)
#    connect_param!(m, :EquityWeighting => :gdp_percap_aftercosts, :SLRDamages => :gdp_percap_aftercosts)
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

function getpage(scenario::String="NDCs", use_permafrost::Bool=true)
    m = Model()
    set_dimension!(m, :time, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_dimension!(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])

    if @isdefined permafr_master
        if permafr_master == "No"
            buildpage(m, scenario, false)
        elseif permafr_master == "Yes"
            buildpage(m, scenario, use_permafrost)
        else
            error("The permafr_master parameter must be set to Yes or No. Please adjust the parameter")
        end
    else
        buildpage(m, scenario, use_permafrost)
    end

    # next: add vector and panel example
    initpage(m)

    return m
end
