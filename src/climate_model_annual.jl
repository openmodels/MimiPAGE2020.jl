include("utils/load_parameters.jl")
include("components/RCPSSPScenario.jl")
include("components/CO2emissions.jl")
include("components/CO2cycle.jl")
include("components/CO2forcing.jl")
include("components/CH4emissions.jl")
include("components/CH4cycle.jl")
include("components/CH4forcing.jl")
include("components/N2Oemissions.jl")
include("components/N2Ocycle.jl")
include("components/N2Oforcing.jl")
include("components/LGemissions.jl")
include("components/LGcycle.jl")
include("components/LGforcing.jl")
include("components/SulphateForcing.jl")
include("components/TotalForcing.jl")
include("components/ClimateTemperature_annual.jl")
include("components/PermafrostSiBCASA_annual.jl")
include("components/PermafrostJULES_annual.jl")
include("components/PermafrostTotal_annual.jl")

function climatemodel(scenario::String, use_permafrost::Bool=true, use_seaice::Bool=false)
    m = Model()
    set_dimension!(m, :year, collect(2015:2300))
    set_dimension!(m, :time, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_dimension!(m, :region, ["EU", "USA", "OECD","USSR","China","SEAsia","Africa","LatAmerica"])

    #add all the components
    scenario = addrcpsspscenario(m, scenario)
    climtemp = addclimatetemperature(m, use_seaice)
    if use_permafrost
        permafrost_sibcasa = add_comp!(m, PermafrostSiBCASA)
        permafrost_jules = add_comp!(m, PermafrostJULES)
        permafrost = add_comp!(m, PermafrostTotal)
    end
    co2emit = add_comp!(m,co2emissions)
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

    #connect parameters together
    set_param!(m, :ClimateTemperature, :y_year_ann, collect(2015:2300))
    set_param!(m, :ClimateTemperature, :y_year, [2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.])
    set_param!(m, :ClimateTemperature, :y_year_0, 2015.)
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
    co2cycle[:y_year] = [2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.]
    co2cycle[:y_year_0] = 2015.
    co2cycle[:e_globalCO2emissions] = co2emit[:e_globalCO2emissions]
    co2cycle[:rt_g_globaltemperature] = climtemp[:rt_g_globaltemperature]
    if use_permafrost
        co2cycle[:permte_permafrostemissions] = permafrost[:perm_tot_e_co2]
    end

    connect_param!(m, :co2forcing => :c_CO2concentration, :CO2Cycle => :c_CO2concentration)

    ch4emit[:er_CH4emissionsgrowth] = scenario[:er_CH4emissionsgrowth]
    ch4cycle[:y_year] = [2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.]
    ch4cycle[:y_year_0] = 2015.
    ch4cycle[:e_globalCH4emissions] = ch4emit[:e_globalCH4emissions]
    ch4cycle[:rtl_g0_baselandtemp] = climtemp[:rtl_g0_baselandtemp]
    ch4cycle[:rtl_g_landtemperature] = climtemp[:rtl_g_landtemperature]
    if use_permafrost
        ch4cycle[:permtce_permafrostemissions] = permafrost[:perm_tot_ce_ch4]
    end

    connect_param!(m, :ch4forcing => :c_CH4concentration, :CH4Cycle => :c_CH4concentration)
    connect_param!(m, :ch4forcing => :c_N2Oconcentration, :n2ocycle => :c_N2Oconcentration)

    n2oemit[:er_N2Oemissionsgrowth] = scenario[:er_N2Oemissionsgrowth]
    set_param!(m, :n2ocycle, :y_year, [2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.])
    set_param!(m, :n2ocycle, :y_year_0, 2015.)
    connect_param!(m, :n2ocycle => :e_globalN2Oemissions, :n2oemissions => :e_globalN2Oemissions)
    connect_param!(m, :n2ocycle => :rtl_g0_baselandtemp, :ClimateTemperature => :rtl_g0_baselandtemp)
    connect_param!(m, :n2ocycle => :rtl_g_landtemperature, :ClimateTemperature => :rtl_g_landtemperature)

    connect_param!(m, :n2oforcing => :c_CH4concentration, :CH4Cycle => :c_CH4concentration)
    connect_param!(m, :n2oforcing => :c_N2Oconcentration, :n2ocycle => :c_N2Oconcentration)

    lgemit[:er_LGemissionsgrowth] = scenario[:er_LGemissionsgrowth]
    set_param!(m, :LGcycle, :y_year, [2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.])
    set_param!(m, :LGcycle, :y_year_0, 2015.)
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

    # next: add vector and panel example
    p = load_parameters(m)
    p["y_year_ann"] = Mimi.dim_keys(m.md, :year)
    p["y_year_0"] = 2015.
    p["y_year"] = Mimi.dim_keys(m.md, :time)
    set_leftover_params!(m, p)

    run(m)
    m
end
