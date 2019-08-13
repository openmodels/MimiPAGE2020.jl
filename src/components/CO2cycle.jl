using Mimi

use_permafrost = true

@defcomp CO2Cycle begin
    # Permafrost outputs
    permte0_permafrostemissions0 = Parameter(unit="Mtonne")
    permte_permafrostemissions = Parameter(index=[time], unit="Mtonne")

    e_globalCO2emissions = Parameter(index=[time], unit="Mtonne/year")
    e0_globalCO2emissions = Parameter(unit="Mtonne/year", default=41223.85968577856)

    pic_preindustconcCO2=Parameter(unit="ppbv", default=278000.)
    exc_excessconcCO2=Variable(unit="ppbv")
    c0_CO2concbaseyr=Parameter(unit="ppbv", default=400859.5833333334)
    re_remainCO2=Variable(index=[time],unit="Mtonne")
    re_remainCO2base=Variable(unit="Mtonne")
    renoccf_remainCO2wocc=Variable(index=[time],unit="Mtonne")
    air_CO2fractioninatm=Parameter(unit="%", default=62.00)
    stay_fractionCO2emissionsinatm=Parameter(default=0.2341802168612297)#percent co2 stay but not in percent
    ccf_CO2feedback=Parameter(unit="%/degreeC", default=0.0)
    ccfmax_maxCO2feedback=Parameter(unit="%", default=20.0)
    ce_0_basecumCO2emissions=Parameter(unit="Mtonne", default=2040000.)
    conoccf_concentrationCO2wocc=Variable(index=[time], unit="ppbv")
    y_year=Parameter(index=[time],unit="year")
    y_year_0=Parameter(unit="year")
    res_CO2atmlifetime=Parameter(unit="year", default=73.3333333333333)
    den_CO2density=Parameter(unit="Mtonne/ppbv", default=7.8)
    rt_g0_baseglobaltemp=Parameter(unit="degreeC", default=0.9461666666666667)
    rt_g_globaltemperature=Parameter(index=[time],unit="degreeC")


    # Parameters for components of CO2
    thist_timescaleco2hist = Parameter( unit="year", default=49.59054463320648)
    corrf_correctionfactorco2_0 = Parameter(default=0.8177307839027955)
    a1_percentco2oceanlong=Parameter(unit="%", default=22.97348182941324)
    a2_percentco2oceanshort=Parameter(unit="%", default=26.64454562239661)
    a3_percentco2land=Parameter(unit="%", default=26.96395086206718)
    t1_timeco2oceanlong=Parameter(unit="year", default=312.54206687556456)
    t2_timeco2oceanshort=Parameter(unit="year", default=34.873449489671636)
    t3_timeco2land=Parameter(unit="year", default=4.257701532922862)

    # Projections for components of CO2
    asymptote_co2_hist =Variable(index=[time], unit="Mtonne")
    ocean_long_uptake_component_hist=Variable(index=[time], unit="Mtonne")
    ocean_short_uptake_component_hist=Variable(index=[time], unit="Mtonne")
    land_uptake_co2hist=Variable(index=[time], unit="Mtonne")

    asymptote_co2_proj=Variable(index=[time], unit="Mtonne")
    ocean_long_uptake_component_proj=Variable(index=[time], unit="Mtonne")
    ocean_short_uptake_component_proj=Variable(index=[time], unit="Mtonne")
    land_uptake_co2_proj=Variable(index=[time], unit="Mtonne")

    te_totalemissions = Variable(index=[time], unit="Mtonne/year")
    c_CO2concentration=Variable(index=[time],unit="ppbv")

    function run_timestep(p, v, d, t)

        te0_totalemissions0 = p.e0_globalCO2emissions + p.permte0_permafrostemissions0
        if is_first(t)
            #adapted from eq.1 in Hope(2006) - calculate excess concentration in base year
            v.exc_excessconcCO2=p.c0_CO2concbaseyr-p.pic_preindustconcCO2
            #Eq. 2 from Hope (2006) - base-year remaining emissions
            v.re_remainCO2base=v.exc_excessconcCO2*p.den_CO2density

            v.asymptote_co2_hist[t] = p.corrf_correctionfactorco2_0 * te0_totalemissions0 * p.thist_timescaleco2hist * p.stay_fractionCO2emissionsinatm
            v.ocean_long_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * te0_totalemissions0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100) * exp(-(p.y_year[t]-p.y_year_0)/p.t1_timeco2oceanlong)
            v.ocean_short_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * te0_totalemissions0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100) * exp(-(p.y_year[t]-p.y_year_0)/p.t2_timeco2oceanshort)
            v.land_uptake_co2hist[t]=p.corrf_correctionfactorco2_0 * te0_totalemissions0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t3_timeco2land)) * (p.a3_percentco2land/100) * exp(-(p.y_year[t]-p.y_year_0)/p.t3_timeco2land)

            v.te_totalemissions[t] = p.e_globalCO2emissions[t] + p.permte_permafrostemissions[t]
            v.asymptote_co2_proj[t] = 0.5*(te0_totalemissions0 + v.te_totalemissions[t]) * (p.y_year[t]-p.y_year_0) * p.stay_fractionCO2emissionsinatm
            v.ocean_long_uptake_component_proj[t] = 0.5*(te0_totalemissions0 + v.te_totalemissions[t]) * p.t1_timeco2oceanlong * (1 - exp(-(p.y_year[t]-p.y_year_0)/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100)
            v.ocean_short_uptake_component_proj[t] = 0.5*(te0_totalemissions0 + v.te_totalemissions[t]) * p.t2_timeco2oceanshort * (1 - exp(-(p.y_year[t]-p.y_year_0)/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100)
            v.land_uptake_co2_proj[t] = 0.5*(te0_totalemissions0 + v.te_totalemissions[t]) * p.t3_timeco2land * (1 - exp(-(p.y_year[t]-p.y_year_0)/p.t3_timeco2land)) * p.a3_percentco2land/100
        else
            v.te_totalemissions[t] = p.e_globalCO2emissions[t] + p.permte_permafrostemissions[t]

            v.asymptote_co2_hist[t] = p.corrf_correctionfactorco2_0 * te0_totalemissions0 * p.thist_timescaleco2hist * p.stay_fractionCO2emissionsinatm
            v.ocean_long_uptake_component_hist[t] = p.corrf_correctionfactorco2_0 * te0_totalemissions0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100)*exp(-(p.y_year[t]-p.y_year_0)/p.t1_timeco2oceanlong)
            v.ocean_short_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * te0_totalemissions0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100)*exp(-(p.y_year[t]-p.y_year_0)/p.t2_timeco2oceanshort)
            v.land_uptake_co2hist[t]=p.corrf_correctionfactorco2_0 * te0_totalemissions0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t3_timeco2land)) * (p.a3_percentco2land/100)*exp(-(p.y_year[t]-p.y_year_0)/p.t3_timeco2land)

            v.asymptote_co2_proj[t] = v.asymptote_co2_proj[t-1] + 0.5*(v.te_totalemissions[t-1] + v.te_totalemissions[t]) * (p.y_year[t]-p.y_year[t-1]) * p.stay_fractionCO2emissionsinatm
            v.ocean_long_uptake_component_proj[t]=v.ocean_long_uptake_component_proj[t-1]*exp(-(p.y_year[t]-p.y_year[t-1])/p.t1_timeco2oceanlong)+0.5 * (v.te_totalemissions[t-1] + v.te_totalemissions[t]) * p.t1_timeco2oceanlong * (1 - exp(-(p.y_year[t]-p.y_year[t-1])/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100)
            v.ocean_short_uptake_component_proj[t]=v.ocean_short_uptake_component_proj[t-1] * exp(-(p.y_year[t]-p.y_year[t-1])/p.t2_timeco2oceanshort)+ 0.5 * (v.te_totalemissions[t-1] + v.te_totalemissions[t]) * p.t2_timeco2oceanshort * (1 - exp(-(p.y_year[t]-p.y_year[t-1])/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100)
            v.land_uptake_co2_proj[t]=v.land_uptake_co2_proj[t-1]*exp(-(p.y_year[t]-p.y_year[t-1])/p.t3_timeco2land)+0.5 * (v.te_totalemissions[t-1] + v.te_totalemissions[t]) * p.t3_timeco2land * (1 - exp(-(p.y_year[t]-p.y_year[t-1])/p.t3_timeco2land)) * p.a3_percentco2land/100
        end

        #remaining emmissions C02 before ccf
        v.renoccf_remainCO2wocc[t]=v.asymptote_co2_hist[t]+v.ocean_long_uptake_component_hist[t]+v.ocean_short_uptake_component_hist[t]+v.land_uptake_co2hist[t]+v.asymptote_co2_proj[t]+v.ocean_long_uptake_component_proj[t]+v.ocean_short_uptake_component_proj[t]+v.land_uptake_co2_proj[t]
        #CO2 concentration CO2 before CCF
        v.conoccf_concentrationCO2wocc[t]=p.pic_preindustconcCO2+v.exc_excessconcCO2*(v.renoccf_remainCO2wocc[t]*v.re_remainCO2base)
        v.re_remainCO2[t]=v.renoccf_remainCO2wocc[t]

        #eq.11 from Hope(2006) - CO2 concentration
        v.c_CO2concentration[t]=p.pic_preindustconcCO2+v.exc_excessconcCO2 * v.re_remainCO2[t]/v.re_remainCO2base
    end
end

function addco2cycle(model::Model, use_permafrost::Bool)
    co2cycle = add_comp!(model, CO2Cycle)

    if use_permafrost
        co2cycle[:permte0_permafrostemissions0] = 692.2476420621228
        co2cycle[:corrf_correctionfactorco2_0] = 0.8177307839027955
        co2cycle[:thist_timescaleco2hist] = 49.59054463320648
    else
        co2cycle[:permte0_permafrostemissions0] = 0
        co2cycle[:permte_permafrostemissions] = zeros(10)
        co2cycle[:corrf_correctionfactorco2_0] = 0.834514918731254
        co2cycle[:thist_timescaleco2hist] = 49.36461591688456
    end

    co2cycle
end
