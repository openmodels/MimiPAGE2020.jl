using Mimi

export getpage

include("../../src/utils/load_parameters.jl")
include("../../src/utils/mctools.jl")

include("mcs_annualGrowth.jl")                          ## done - based on mcs_ARvariability.jl + added lines (GDP, civvalue, save command) + added functions (compute_scc_mcs & get_scc_mcs) from mcs_growth.jl
include("compute_scc_annual.jl")

include("../../src/components/RCPSSPScenario.jl")
include("../../src/components/extensions/CO2emissions_feedback.jl")
include("../../src/components/CO2cycle.jl")
include("../../src/components/CO2forcing.jl")
include("../../src/components/extensions/CH4emissions_feedback.jl")
include("../../src/components/CH4cycle.jl")
include("../../src/components/CH4forcing.jl")
include("../../src/components/extensions/N2Oemissions_feedback.jl")
include("../../src/components/N2Ocycle.jl")
include("../../src/components/N2Oforcing.jl")
include("../../src/components/extensions/LGemissions_feedback.jl")
include("../../src/components/LGcycle.jl")
include("../../src/components/LGforcing.jl")
include("../../src/components/SulphateForcing.jl")
include("../../src/components/TotalForcing.jl")
include("../../src/components/ClimateTemperature.jl")
include("../../src/components/extensions/ClimateTemperature_ARvariability.jl")       # runs default with AR variability!
include("../../src/components/SeaLevelRise.jl")
include("../../src/components/GDP.jl")
include("../../src/components/extensions/GDP_annual.jl")                   # annualised, based on the PAGE-Growth file
include("../../src/components/extensions/GDP_growth.jl")                   # annualised, based on the PAGE-Growth file
include("../../src/components/extensions/SLRDamages_growth.jl")
include("../../src/components/extensions/SLRDamages_annualGrowth.jl")            # annualised, based on the PAGE-Growth file
include("../../src/components/MarketDamages.jl")         # annualised, based on the PAGE-ANN file
include("../../src/components/extensions/MarketDamages_annual.jl")         # annualised, based on the PAGE-ANN file
include("../../src/components/MarketDamagesBurke.jl")    # annualised, based on the PAGE-ANN file
include("../../src/components/extensions/MarketDamagesBurke_annual.jl")    # annualised, based on the PAGE-ANN file
include("../../src/components/NonMarketDamages.jl")      # annualised, based on the PAGE-ANN file
include("../../src/components/extensions/NonMarketDamages_annual.jl")      # annualised, based on the PAGE-ANN file
include("../../src/components/Discontinuity.jl")                           ## stays same as normal annual damages!
include("../../src/components/extensions/Discontinuity_annual.jl")                           ## stays same as normal annual damages!
include("../../src/components/AdaptationCosts.jl")       # annualised, based on the PAGE-ICE file
include("../../src/components/extensions/AdaptationCosts_annual.jl")       # annualised, based on the PAGE-ICE file
include("../../src/components/AbatementCostParameters.jl")
include("../../src/components/AbatementCosts.jl")
include("../../src/components/TotalAbatementCosts.jl")
include("../../src/components/extensions/TotalAdaptationCosts_annual.jl")  # annualised, based on the PAGE-ICE file
include("../../src/components/Population.jl")
include("../../src/components/extensions/EquityWeighting_annualGrowth.jl")       # annualised, based on the PAGE-Growth file
include("../../src/components/PermafrostSiBCASA.jl")
include("../../src/components/PermafrostJULES.jl")
include("../../src/components/PermafrostTotal.jl")

function buildpage(m::Model, scenario::String, use_permafrost::Bool=true, use_seaice::Bool=true, use_page09damages::Bool=false)

    # add all the components
    scenario = addrcpsspscenario(m, scenario)
    climtemp = addclimatetemperature(m, use_seaice)
    climtemp_arv = addclimatetemperature_ARvariability(m, use_seaice)
    if use_permafrost
        permafrost_sibcasa = add_comp!(m, PermafrostSiBCASA)
        permafrost_jules = add_comp!(m, PermafrostJULES)
        permafrost = add_comp!(m, PermafrostTotal)
    end

    # Socio-Economics
    population = addpopulation(m)
    gdp = add_comp!(m, GDP)
    gdp_grw = add_comp!(m, GDP_growth)
    gdp_ann = add_comp!(m, GDP_annual)

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
    add_comp!(m, SeaLevelRise)

    # Abatement Costs
    abatementcostparameters_CO2 = addabatementcostparameters(m, :CO2)
    abatementcostparameters_CH4 = addabatementcostparameters(m, :CH4)
    abatementcostparameters_N2O = addabatementcostparameters(m, :N2O)
    abatementcostparameters_Lin = addabatementcostparameters(m, :Lin)

    set_param!(m, :automult_autonomoustechchange, .65)

    abatementcosts_CO2 = addabatementcosts(m, :CO2)
    abatementcosts_CH4 = addabatementcosts(m, :CH4)
    abatementcosts_N2O = addabatementcosts(m, :N2O)
    abatementcosts_Lin = addabatementcosts(m, :Lin)
    add_comp!(m, TotalAbatementCosts)

    # Adaptation Costs
    adaptationcosts_sealevel = addadaptationcosts_sealevel(m)
    adaptationcosts_economic = addadaptationcosts_economic(m)
    adaptationcosts_noneconomic = addadaptationcosts_noneconomic(m)
    add_comp!(m, TotalAdaptationCosts)

    adaptationcosts_sealevel_ann = addadaptationcosts_sealevel_ann(m)
    adaptationcosts_economic_ann = addadaptationcosts_economic_ann(m)
    adaptationcosts_noneconomic_ann = addadaptationcosts_noneconomic_ann(m)
    add_comp!(m, TotalAdaptationCosts_annual)

    # Impacts
    slrdamages = addslrdamages(m)
    slrdamages_ann = addslrdamages_annualgrowth(m)
    marketdamages = addmarketdamages(m)
    marketdamages_ann = addmarketdamages_annual(m)
    marketdamagesburke = addmarketdamagesburke(m)
    marketdamagesburke_ann = addmarketdamagesburke_annual(m)
    nonmarketdamages = addnonmarketdamages(m)
    nonmarketdamages_ann = addnonmarketdamages_annual(m)
    discontinuity = add_comp!(m, Discontinuity)
    discontinuity_ann = add_comp!(m, Discontinuity_annual)

    # Equity weighting and Total Costs
    equityweighting = add_comp!(m, EquityWeighting)

    # connect parameters together
    connect_param!(m, :ClimateTemperature => :fant_anthroforcing, :TotalForcing => :fant_anthroforcing)
    climtemp_arv[:pt_g_preliminarygmst] = climtemp[:pt_g_preliminarygmst]

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

    # feed counterfactual GDP (for level effects) and actual GDP into emissions components to re-scale scenario emissions
    connect_param!(m, :co2emissions => :gdp_leveleffect, :GDP => :gdp)
    connect_param!(m, :co2emissions => :gdp, :GDP_growth => :gdp)

    connect_param!(m, :CO2Cycle => :e_globalCO2emissions, :co2emissions => :e_globalCO2emissions)
    connect_param!(m, :CO2Cycle => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)
    if use_permafrost
        co2cycle[:permte_permafrostemissions] = permafrost[:perm_tot_e_co2]
    end

    connect_param!(m, :co2forcing => :c_CO2concentration, :CO2Cycle => :c_CO2concentration)

    ch4emit[:er_CH4emissionsgrowth] = scenario[:er_CH4emissionsgrowth]

    connect_param!(m, :ch4emissions => :gdp_leveleffect, :GDP => :gdp)
    connect_param!(m, :ch4emissions => :gdp, :GDP_growth => :gdp)

    connect_param!(m, :CH4Cycle => :e_globalCH4emissions, :ch4emissions => :e_globalCH4emissions)
    connect_param!(m, :CH4Cycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :CH4Cycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)
    if use_permafrost
        ch4cycle[:permtce_permafrostemissions] = permafrost[:perm_tot_ce_ch4]
    end

    connect_param!(m, :ch4forcing => :c_CH4concentration, :CH4Cycle => :c_CH4concentration)
    connect_param!(m, :ch4forcing => :c_N2Oconcentration, :n2ocycle => :c_N2Oconcentration)

    n2oemit[:er_N2Oemissionsgrowth] = scenario[:er_N2Oemissionsgrowth]

    connect_param!(m, :n2oemissions  => :gdp_leveleffect, :GDP => :gdp)
    connect_param!(m, :n2oemissions  => :gdp, :GDP_growth => :gdp)

    connect_param!(m, :n2ocycle => :e_globalN2Oemissions, :n2oemissions => :e_globalN2Oemissions)
    connect_param!(m, :n2ocycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :n2ocycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)

    connect_param!(m, :n2oforcing => :c_CH4concentration, :CH4Cycle => :c_CH4concentration)
    connect_param!(m, :n2oforcing => :c_N2Oconcentration, :n2ocycle => :c_N2Oconcentration)

    lgemit[:er_LGemissionsgrowth] = scenario[:er_LGemissionsgrowth]

    connect_param!(m, :LGemissions => :gdp_leveleffect, :GDP => :gdp)
    connect_param!(m, :LGemissions => :gdp, :GDP_growth => :gdp)

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

    connect_param!(m, :GDP_growth => :pop_population, :Population => :pop_population)
    gdp_grw[:grw_gdpgrowthrate] = scenario[:grw_gdpgrowthrate]
    gdp_grw[:gdp_leveleffect] = gdp[:gdp]

    connect_param!(m, :GDP_annual => :pop_population, :Population => :pop_population)
    gdp_ann[:grw_gdpgrowthrate] = scenario[:grw_gdpgrowthrate]
    gdp_ann[:cbabsn_pcconsumptionbound_neighbourhood] = gdp_grw[:cbabsn_pcconsumptionbound_neighbourhood]
    gdp_ann[:cbaux1_pcconsumptionbound_auxiliary1] = gdp_grw[:cbaux1_pcconsumptionbound_auxiliary1]
    gdp_ann[:cbaux2_pcconsumptionbound_auxiliary2] = gdp_grw[:cbaux2_pcconsumptionbound_auxiliary2]

    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    if use_page09damages
        connect_param!(m, :GDP_growth => :isat_ImpactinclSaturationandAdaptation, :MarketDamages => :isat_ImpactinclSaturationandAdaptation)
        connect_param!(m, :GDP_annual => :isat_ImpactinclSaturationandAdaptation_ann, :MarketDamages_annual => :isat_ImpactinclSaturationandAdaptation_ann)
    else
        connect_param!(m, :GDP_growth => :isat_ImpactinclSaturationandAdaptation, :MarketDamagesBurke => :isat_ImpactinclSaturationandAdaptation)
        connect_param!(m, :GDP_annual => :isat_ImpactinclSaturationandAdaptation_ann, :MarketDamagesBurke_annual => :isat_ImpactinclSaturationandAdaptation_ann)
    end
    ###############################################

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
    connect_param!(m, :AdaptiveCostsEconomic_annual => :gdp_ann, :GDP_annual => :gdp_ann)
    connect_param!(m, :AdaptiveCostsNonEconomic => :gdp, :GDP => :gdp)
    connect_param!(m, :AdaptiveCostsNonEconomic_annual => :gdp_ann, :GDP_annual => :gdp_ann)
    connect_param!(m, :AdaptiveCostsSeaLevel => :gdp, :GDP => :gdp)
    connect_param!(m, :AdaptiveCostsSeaLevel_annual => :gdp_ann, :GDP_annual => :gdp_ann)

    connect_param!(m, :TotalAdaptationCosts => :ac_adaptationcosts_economic, :AdaptiveCostsEconomic => :ac_adaptivecosts)
    connect_param!(m, :TotalAdaptationCosts_annual => :ac_adaptationcosts_economic_ann, :AdaptiveCostsEconomic_annual => :ac_adaptivecosts_ann)
    connect_param!(m, :TotalAdaptationCosts => :ac_adaptationcosts_noneconomic, :AdaptiveCostsNonEconomic => :ac_adaptivecosts)
    connect_param!(m, :TotalAdaptationCosts_annual => :ac_adaptationcosts_noneconomic_ann, :AdaptiveCostsNonEconomic_annual => :ac_adaptivecosts_ann)
    connect_param!(m, :TotalAdaptationCosts => :ac_adaptationcosts_sealevelrise, :AdaptiveCostsSeaLevel => :ac_adaptivecosts)
    connect_param!(m, :TotalAdaptationCosts_annual => :ac_adaptationcosts_sealevelrise_ann, :AdaptiveCostsSeaLevel_annual => :ac_adaptivecosts_ann)
    connect_param!(m, :TotalAdaptationCosts => :pop_population, :Population => :pop_population)
    connect_param!(m, :TotalAdaptationCosts_annual => :pop_population_ann, :GDP_annual => :pop_population_ann)

    connect_param!(m, :SLRDamages => :s_sealevel, :SeaLevelRise => :s_sealevel)
    connect_param!(m, :SLRDamages => :cons_percap_consumption, :GDP => :cons_percap_consumption)
    connect_param!(m, :SLRDamages => :cons_percap_consumption_0, :GDP => :cons_percap_consumption_0)
    connect_param!(m, :SLRDamages => :tct_per_cap_totalcostspercap, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :SLRDamages => :act_percap_adaptationcosts, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :SLRDamages => :atl_adjustedtolerablelevelofsealevelrise, :AdaptiveCostsSeaLevel => :atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :SLRDamages => :imp_actualreductionSLR, :AdaptiveCostsSeaLevel => :imp_adaptedimpacts)
    connect_param!(m, :SLRDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)
    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    connect_param!(m, :SLRDamages => :cons_percap_consumption_noconvergence, :GDP_growth => :cons_percap_consumption_noconvergence)
    connect_param!(m, :SLRDamages => :cbabsn_pcconsumptionbound_neighbourhood, :GDP_growth => :cbabsn_pcconsumptionbound_neighbourhood)
    connect_param!(m, :SLRDamages => :cbaux1_pcconsumptionbound_auxiliary1, :GDP_growth => :cbaux1_pcconsumptionbound_auxiliary1)
    connect_param!(m, :SLRDamages => :cbaux2_pcconsumptionbound_auxiliary2, :GDP_growth => :cbaux2_pcconsumptionbound_auxiliary2)
    connect_param!(m, :SLRDamages => :cons_percap_consumption_noconvergence, :GDP_growth => :cons_percap_consumption_noconvergence)
    ###############################################

    connect_param!(m, :SLRDamages_annualGrowth => :s_sealevel, :SeaLevelRise => :s_sealevel)
    connect_param!(m, :SLRDamages_annualGrowth => :cons_percap_consumption_ann, :GDP_annual => :cons_percap_consumption_ann)
    connect_param!(m, :SLRDamages_annualGrowth => :tct_per_cap_totalcostspercap, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :SLRDamages_annualGrowth => :act_percap_adaptationcosts_ann, :TotalAdaptationCosts_annual => :act_percap_adaptationcosts_ann)
    connect_param!(m, :SLRDamages_annualGrowth => :atl_adjustedtolerablelevelofsealevelrise_ann, :AdaptiveCostsSeaLevel_annual => :atl_adjustedtolerablelevel_ann, ignoreunits=true)
    connect_param!(m, :SLRDamages_annualGrowth => :imp_actualreductionSLR_ann, :AdaptiveCostsSeaLevel_annual => :imp_adaptedimpacts_ann)
    connect_param!(m, :SLRDamages_annualGrowth => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)
    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    connect_param!(m, :SLRDamages_annualGrowth => :cons_percap_consumption_noconvergence_ann, :GDP_annual => :cons_percap_consumption_noconvergence_ann)
    connect_param!(m, :SLRDamages_annualGrowth => :cbabsn_pcconsumptionbound_neighbourhood, :GDP_growth => :cbabsn_pcconsumptionbound_neighbourhood)
    connect_param!(m, :SLRDamages_annualGrowth => :cbaux1_pcconsumptionbound_auxiliary1, :GDP_growth => :cbaux1_pcconsumptionbound_auxiliary1)
    connect_param!(m, :SLRDamages_annualGrowth => :cbaux2_pcconsumptionbound_auxiliary2, :GDP_growth => :cbaux2_pcconsumptionbound_auxiliary2)
    ###############################################

    connect_param!(m, :MarketDamages => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamages => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamages => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamages => :atl_adjustedtolerableleveloftemprise, :AdaptiveCostsEconomic => :atl_adjustedtolerablelevel, ignoreunits=true) # not required for Burke damages
    connect_param!(m, :MarketDamages => :imp_actualreduction, :AdaptiveCostsEconomic => :imp_adaptedimpacts) # not required for Burke damages
    connect_param!(m, :MarketDamages => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamages_annual => :rtl_realizedtemperature_ann, :ClimateTemperature_ARvariability => :rtl_realizedtemperature_ann)
    connect_param!(m, :MarketDamages_annual => :atl_adjustedtolerableleveloftemprise, :AdaptiveCostsEconomic => :atl_adjustedtolerablelevel, ignoreunits=true) # not required for Burke damages
    connect_param!(m, :MarketDamages_annual => :imp_actualreduction, :AdaptiveCostsEconomic => :imp_adaptedimpacts) # not required for Burke damages
    connect_param!(m, :MarketDamages_annual => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamages_annual => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamages_annual => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :MarketDamagesBurke => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamagesBurke => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamagesBurke => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    connect_param!(m, :MarketDamagesBurke => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)

    marketdamagesburke_ann[:interpolate_parameters] = true
    connect_param!(m, :MarketDamagesBurke_annual => :rtl_realizedtemperature_ann, :ClimateTemperature_ARvariability => :rtl_realizedtemperature_ann)
    connect_param!(m, :MarketDamagesBurke_annual => :rtl_realizedtemperature, :ClimateTemperature => :rtl_realizedtemperature)
    connect_param!(m, :MarketDamagesBurke_annual => :yagg_periodspan, :GDP => :yagg_periodspan) # added for doing in-component summation
    connect_param!(m, :MarketDamagesBurke_annual => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)
    connect_param!(m, :MarketDamagesBurke_annual => :rgdp_per_cap_SLRRemainGDP, :SLRDamages => :rgdp_per_cap_SLRRemainGDP)
    connect_param!(m, :MarketDamagesBurke_annual => :rcons_per_cap_SLRRemainConsumption, :SLRDamages => :rcons_per_cap_SLRRemainConsumption)
    marketdamagesburke_ann[:igdp_ImpactatActualGDPperCap] = marketdamagesburke[:igdp_ImpactatActualGDPperCap]
    marketdamagesburke_ann[:rgdp_per_cap_MarketRemainGDP] = marketdamagesburke[:rgdp_per_cap_MarketRemainGDP]
    marketdamagesburke_ann[:rcons_per_cap_MarketRemainConsumption] = marketdamagesburke[:rcons_per_cap_MarketRemainConsumption]
    marketdamagesburke_ann[:isat_per_cap_ImpactperCapinclSaturationandAdaptation] = marketdamagesburke[:isat_per_cap_ImpactperCapinclSaturationandAdaptation]

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

    set_param!(m, :NonMarketDamages_annual, :interpolate_parameters, true)
    connect_param!(m, :NonMarketDamages_annual => :rtl_realizedtemperature_ann, :ClimateTemperature_ARvariability => :rtl_realizedtemperature_ann)
    connect_param!(m, :NonMarketDamages_annual => :yagg_periodspan, :GDP => :yagg_periodspan) # added for doing in-component summation
    connect_param!(m, :NonMarketDamages_annual => :isatg_impactfxnsaturation, :GDP => :isatg_impactfxnsaturation)
    connect_param!(m, :NonMarketDamages_annual => :atl_adjustedtolerableleveloftemprise, :AdaptiveCostsNonEconomic => :atl_adjustedtolerablelevel, ignoreunits=true)
    connect_param!(m, :NonMarketDamages_annual => :imp_actualreduction, :AdaptiveCostsNonEconomic => :imp_adaptedimpacts)
    connect_param!(m, :NonMarketDamages_annual => :rgdp_per_cap_NonMarketRemainGDP, :NonMarketDamages => :rgdp_per_cap_NonMarketRemainGDP)
    if use_page09damages
        connect_param!(m, :NonMarketDamages_annual => :rgdp_per_cap_MarketRemainGDP_ann, :MarketDamages_annual => :rgdp_per_cap_MarketRemainGDP_ann)
        connect_param!(m, :NonMarketDamages_annual => :rcons_per_cap_MarketRemainConsumption_ann, :MarketDamages_annual => :rcons_per_cap_MarketRemainConsumption_ann)
    else
        connect_param!(m, :NonMarketDamages_annual => :rgdp_per_cap_MarketRemainGDP_ann, :MarketDamagesBurke_annual => :rgdp_per_cap_MarketRemainGDP_ann)
        connect_param!(m, :NonMarketDamages_annual => :rcons_per_cap_MarketRemainConsumption_ann, :MarketDamagesBurke_annual => :rcons_per_cap_MarketRemainConsumption_ann)
    end

    connect_param!(m, :Discontinuity => :rgdp_per_cap_NonMarketRemainGDP, :NonMarketDamages => :rgdp_per_cap_NonMarketRemainGDP)
    connect_param!(m, :Discontinuity => :rt_g_globaltemperature, :ClimateTemperature => :rt_g_globaltemperature)
    connect_param!(m, :Discontinuity => :rcons_per_cap_NonMarketRemainConsumption, :NonMarketDamages => :rcons_per_cap_NonMarketRemainConsumption)
    connect_param!(m, :Discontinuity => :isatg_saturationmodification, :GDP => :isatg_impactfxnsaturation)

    discontinuity_ann[:occurdis_occurrencedummy] = discontinuity[:occurdis_occurrencedummy]
    discontinuity_ann[:isat_per_cap_DiscImpactperCapinclSaturation] = discontinuity[:isat_per_cap_DiscImpactperCapinclSaturation]
    discontinuity_ann[:rcons_per_cap_DiscRemainConsumption] = discontinuity[:rcons_per_cap_DiscRemainConsumption]
    discontinuity_ann[:irefeqdis_eqdiscimpact] = discontinuity[:irefeqdis_eqdiscimpact]

    connect_param!(m, :Discontinuity_annual => :rgdp_per_cap_NonMarketRemainGDP_ann, :NonMarketDamages_annual => :rgdp_per_cap_NonMarketRemainGDP_ann)
    connect_param!(m, :Discontinuity_annual => :rt_g_globaltemperature_ann, :ClimateTemperature_ARvariability => :rt_g_globaltemperature_ann)
    connect_param!(m, :Discontinuity_annual => :rgdp_per_cap_NonMarketRemainGDP_ann, :NonMarketDamages_annual => :rgdp_per_cap_NonMarketRemainGDP_ann)
    connect_param!(m, :Discontinuity_annual => :rcons_per_cap_NonMarketRemainConsumption_ann, :NonMarketDamages_annual => :rcons_per_cap_NonMarketRemainConsumption_ann)
    connect_param!(m, :Discontinuity_annual => :yagg_periodspan, :GDP => :yagg_periodspan) # added for doing in-component summation
    connect_param!(m, :Discontinuity_annual => :isatg_saturationmodification, :GDP => :isatg_impactfxnsaturation)

    connect_param!(m, :EquityWeighting => :pop_population, :Population => :pop_population)
    connect_param!(m, :EquityWeighting => :pop_population_ann, :GDP_annual => :pop_population_ann)
    connect_param!(m, :EquityWeighting => :tct_percap_totalcosts_total, :TotalAbatementCosts => :tct_per_cap_totalcostspercap)
    connect_param!(m, :EquityWeighting => :tct_percap_totalcosts_total_ann, :SLRDamages_annualGrowth => :tct_per_cap_totalcostspercap_ann)
    connect_param!(m, :EquityWeighting => :act_adaptationcosts_total, :TotalAdaptationCosts => :act_adaptationcosts_total)
    connect_param!(m, :EquityWeighting => :act_adaptationcosts_total_ann, :TotalAdaptationCosts_annual => :act_adaptationcosts_total_ann)
    connect_param!(m, :EquityWeighting => :act_percap_adaptationcosts, :TotalAdaptationCosts => :act_percap_adaptationcosts)
    connect_param!(m, :EquityWeighting => :act_percap_adaptationcosts_ann, :TotalAdaptationCosts_annual => :act_percap_adaptationcosts_ann)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption, :GDP => :cons_percap_consumption)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption_ann, :GDP_annual => :cons_percap_consumption_ann)
    connect_param!(m, :EquityWeighting => :cons_percap_consumption_0, :GDP => :cons_percap_consumption_0)
    connect_param!(m, :EquityWeighting => :cons_percap_aftercosts, :SLRDamages => :cons_percap_aftercosts)
    connect_param!(m, :EquityWeighting => :cons_percap_aftercosts_ann, :SLRDamages_annualGrowth => :cons_percap_aftercosts_ann)
    connect_param!(m, :EquityWeighting => :rcons_percap_dis, :Discontinuity => :rcons_per_cap_DiscRemainConsumption)
    connect_param!(m, :EquityWeighting => :rcons_percap_dis_ann, :Discontinuity_annual => :rcons_per_cap_DiscRemainConsumption_ann)
    connect_param!(m, :EquityWeighting => :yagg_periodspan, :GDP => :yagg_periodspan)

    ###############################################
    # Growth Effects - additional variables and parameters
    ###############################################
    connect_param!(m, :EquityWeighting => :grwnet_realizedgdpgrowth, :GDP_growth => :grwnet_realizedgdpgrowth)
    connect_param!(m, :EquityWeighting => :grwnet_realizedgdpgrowth_ann, :GDP_annual => :grwnet_realizedgdpgrowth_ann)
    connect_param!(m, :EquityWeighting => :lgdp_gdploss, :GDP_growth => :lgdp_gdploss)
    connect_param!(m, :EquityWeighting => :lgdp_gdploss_ann, :GDP_annual => :lgdp_gdploss_ann)
    ###############################################
    equityweighting[:popgrw_populationgrowth] = scenario[:popgrw_populationgrowth]

    return m
end

function initpage(m::Model)
    setorup_param!(m, :y_year_ann, collect(2015:2300))
    p = load_parameters(m)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)
end

function getpage(scenario::String="NDCs", use_permafrost::Bool=true, use_seaice::Bool=true, use_page09damages::Bool=false)
    m = Model()
    set_dimension!(m, :year, collect(2015:2300))
    set_dimension!(m, :time, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_dimension!(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])
    set_dimension!(m, :draw, Array(1:10^6))

    buildpage(m, scenario, use_permafrost, use_seaice, use_page09damages)

    # next: add vector and panel example
    initpage(m)

    return m
end

get_model = getpage
