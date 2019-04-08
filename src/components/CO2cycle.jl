using Mimi

@defcomp co2cycle begin
    e_globalCO2emissions=Parameter(index=[time],unit="Mtonne/year")
    e0_globalCO2emissions=Parameter(unit="Mtonne/year", default=41223.85968577856)
    c_CO2concentration=Variable(index=[time],unit="ppbv")
    pic_preindustconcCO2=Parameter(unit="ppbv", default=278000.)
    exc_excessconcCO2=Variable(unit="ppbv")
    c0_CO2concbaseyr=Parameter(unit="ppbv", default=400859.5833333334)
    re_remainCO2=Variable(index=[time],unit="Mtonne")
    re_remainCO2base=Variable(unit="Mtonne")
    renoccf_remainCO2wocc=Variable(index=[time],unit="Mtonne")
    air_CO2fractioninatm=Parameter(unit="%", default=62.00)
    stay_fractionCO2emissionsinatm=Parameter(default=0.2341802168612297)#percent co2 stay but not in percent
    tea_CO2emissionstoatm=Variable(index=[time],unit="Mtonne/year")
    teay_CO2emissionstoatm=Variable(index=[time],unit="Mtonne/t")
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
    a1_percentco2oceanlong=Parameter(unit="%", default=22.97)
    a2_percentco2oceanshort=Parameter(unit="%", default=26.64)
    a3_percentco2land=Parameter(unit="%", default=26.96)
    t1_timeco2oceanlong=Parameter(unit="year", default=312.54)
    t2_timeco2oceanshort=Parameter(unit="year", default=34.87)
    t3_timeco2land=Parameter(unit="year", default=4.26)


    #New Parameters as fixed
    thist_timescaleco2hist=Parameter( unit="year", default=49.59054463)
    corrf_correctionfactorco2_0=Parameter(default=0.817730784)

    #New parameters as functions and using emissions
    #thist_timescaleco2hist=Parameter(unit="year")
    #corrf_correctionfactorco2_0=Parameter(default=0.817730784)

    #renoccf0_remainCO2wocc=Parameter(unit="Mtonne")#not added in file
    asymptote_co2_hist =Variable(index=[time], unit="Mtonne")
    ocean_long_uptake_component_hist=Variable(index=[time], unit="Mtonne")
    ocean_short_uptake_component_hist=Variable(index=[time], unit="Mtonne")
    land_uptake_co2hist=Variable(index=[time], unit="Mtonne")

    asymptote_co2_proj=Variable(index=[time], unit="Mtonne")
    ocean_long_uptake_component_proj=Variable(index=[time], unit="Mtonne")
    ocean_short_uptake_component_proj=Variable(index=[time], unit="Mtonne")
    land_uptake_co2_proj=Variable(index=[time], unit="Mtonne")


    function run_timestep(p, v, d, t)

        if is_first(t)
            #CO2 emissions gain calculated based on PAGE 2009
            gain=p.ccf_CO2feedback*p.rt_g0_baseglobaltemp
            #eq.6 from Hope (2006) - emissions to atmosphere depend on the sum of natural and anthropogenic emissions
            tea0=p.e0_globalCO2emissions*p.air_CO2fractioninatm/100
            v.tea_CO2emissionstoatm[t]=(p.e_globalCO2emissions[t])*p.air_CO2fractioninatm/100
            v.teay_CO2emissionstoatm[t]=(v.tea_CO2emissionstoatm[t]+tea0)*(p.y_year[t]-p.y_year_0)/2
            #adapted from eq.1 in Hope(2006) - calculate excess concentration in base year
            v.exc_excessconcCO2=p.c0_CO2concbaseyr-p.pic_preindustconcCO2
            #Eq. 2 from Hope (2006) - base-year remaining emissions
            v.re_remainCO2base=v.exc_excessconcCO2*p.den_CO2density
            #PAGE 2009 initial remaining emissions without CO2 feedback
            renoccf0_remainCO2wocc=v.re_remainCO2base/(1+gain/100)

            #update remaining emissions

            #Functions for two parameters that are fixed
            # eq. 8 from Hope (2006) - baseline cumulative emissions to atmosphere
            #ceabase=p.ce_0_basecumCO2emissions*p.air_CO2fractioninatm/100
            #p.thist_timescaleco2hist=ceabase/tea0
            #p.corrf_correctionfactorco2_0=renoccf0_remainCO2wocc/(tea0*p.thist_timescaleco2hist*((p.stay_fractionCO2emissionsinatm)+(p.a1_percentco2oceanlong/100)/(1+p.thist_timescaleco2hist/p.t1_timeco2oceanlong)
            #    +(p.a2_percentco2oceanshort/100)/(1+p.thist_timescaleco2hist/p.t2_timeco2oceanshort)+(p.a3_percentco2land/100)/(1+p.thist_timescaleco2hist/p.t3_timeco2land)))

            v.asymptote_co2_hist[t] = (p.corrf_correctionfactorco2_0 * tea0) * (p.thist_timescaleco2hist) * (p.stay_fractionCO2emissionsinatm)
            v.ocean_long_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * tea0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100)
            v.ocean_short_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * tea0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100)
            v.land_uptake_co2hist[t]=p.corrf_correctionfactorco2_0 * tea0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t3_timeco2land)) * (p.a3_percentco2land/100)

            v.asymptote_co2_proj[t]=0
            v.ocean_long_uptake_component_proj[t]=0
            v.ocean_short_uptake_component_proj[t]=0
            v.land_uptake_co2_proj[t]=0

            #remaining emmissions C02 before ccf
            v.renoccf_remainCO2wocc[t]=v.asymptote_co2_hist[t]+v.ocean_long_uptake_component_hist[t]+v.ocean_short_uptake_component_hist[t]+v.land_uptake_co2hist[t]+v.asymptote_co2_proj[t]+v.ocean_long_uptake_component_proj[t]+v.ocean_short_uptake_component_proj[t]+v.land_uptake_co2_proj[t]
            #CO2 concentration CO2 before CCF
            v.conoccf_concentrationCO2wocc[t]=p.pic_preindustconcCO2+v.exc_excessconcCO2*(v.renoccf_remainCO2wocc[t]*v.re_remainCO2base)

            #Co2 concentration
            v.c_CO2concentration[t]=v.conoccf_concentrationCO2wocc[t]+p.ccf_CO2feedback
            #Hope 2009 - remaining emissions with CO2 feedback
            v.re_remainCO2[t]=v.renoccf_remainCO2wocc[t]*(1+gain/100)

        else
            #CO2 emissions gain calculated based on PAGE 2009
            gain=min(p.ccf_CO2feedback*p.rt_g_globaltemperature[t-1],p.ccfmax_maxCO2feedback)
            #PAGE 2009 initial remaining emissions without CO2 feedback
            renoccf0_remainCO2wocc=v.re_remainCO2base/(1+gain/100)
            #eq.6 from Hope (2006) - emissions to atmosphere depend on the sum of natural and anthropogenic emissions
            tea0=p.e0_globalCO2emissions*p.air_CO2fractioninatm/100#added for the update
            v.tea_CO2emissionstoatm[t]=(p.e_globalCO2emissions[t])*p.air_CO2fractioninatm/100
            #eq.7 from Hope (2006) - total emissions over time period
            v.teay_CO2emissionstoatm[t]=(v.tea_CO2emissionstoatm[t]+v.tea_CO2emissionstoatm[t-1])*(p.y_year[t]-p.y_year[t-1])/2

            #update remaining emissions
            v.asymptote_co2_hist[t]=p.corrf_correctionfactorco2_0 * tea0* p.thist_timescaleco2hist * (p.stay_fractionCO2emissionsinatm)
            v.ocean_long_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * tea0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100)*exp(-(p.y_year[t]-p.y_year_0)/p.t1_timeco2oceanlong)
            v.ocean_short_uptake_component_hist[t]=p.corrf_correctionfactorco2_0 * tea0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100)*exp(-(p.y_year[t]-p.y_year_0)/p.t2_timeco2oceanshort)
            v.land_uptake_co2hist[t]=p.corrf_correctionfactorco2_0 * tea0 * (p.thist_timescaleco2hist / (1 + p.thist_timescaleco2hist/p.t3_timeco2land)) * (p.a3_percentco2land/100)*exp(-(p.y_year[t]-p.y_year_0)/p.t3_timeco2land)

            v.asymptote_co2_proj[t] = v.asymptote_co2_proj[t-1] + 0.5*( v.teay_CO2emissionstoatm[t-1] +  v.teay_CO2emissionstoatm[t]) * (p.y_year[t]-p.y_year[t-1]) * p.stay_fractionCO2emissionsinatm #check if it's teay or tea

            v.ocean_long_uptake_component_proj[t]=v.ocean_long_uptake_component_proj[t-1]*exp(-(p.y_year[t]-p.y_year[t-1])/p.t1_timeco2oceanlong)+0.5 * (v.teay_CO2emissionstoatm[t-1] +  v.teay_CO2emissionstoatm[t]) * p.t1_timeco2oceanlong * (1 - exp(-(p.y_year[t]-p.y_year[t-1])/p.t1_timeco2oceanlong)) * (p.a1_percentco2oceanlong/100)
            v.ocean_short_uptake_component_proj[t]=v.ocean_short_uptake_component_proj[t-1] * exp(-(p.y_year[t]-p.y_year[t-1])/p.t2_timeco2oceanshort)+ 0.5 * (v.teay_CO2emissionstoatm[t-1] +  v.teay_CO2emissionstoatm[t]) * p.t2_timeco2oceanshort * (1 - exp(-(p.y_year[t]-p.y_year[t-1])/p.t2_timeco2oceanshort)) * (p.a2_percentco2oceanshort/100)
            v.land_uptake_co2_proj[t]=v.land_uptake_co2_proj[t-1]*exp(-(p.y_year[t]-p.y_year[t-1])/p.t3_timeco2land)+0.5 * (v.teay_CO2emissionstoatm[t-1]+v.teay_CO2emissionstoatm[t]) * p.t3_timeco2land * (1 - exp(-(p.y_year[t]-p.y_year[t-1])/p.t3_timeco2land)) * p.a3_percentco2land/100

            #remaining emmissions C02 before ccf
            v.renoccf_remainCO2wocc[t]= v.asymptote_co2_hist[t] + v.ocean_long_uptake_component_hist[t] + v.ocean_short_uptake_component_hist[t] + v.land_uptake_co2hist[t] + v.asymptote_co2_proj[t] + v.ocean_long_uptake_component_proj[t] + v.ocean_short_uptake_component_proj[t] + v.land_uptake_co2_proj[t]
            #CO2 concentration CO2 before CCF
            v.conoccf_concentrationCO2wocc[t]= p.pic_preindustconcCO2 + v.exc_excessconcCO2*v.renoccf_remainCO2wocc[t]*v.re_remainCO2base
            #Hope 2009 - remaining emissions with CO2 feedback
            v.re_remainCO2[t]=v.renoccf_remainCO2wocc[t]*(1+gain/100)
            #eq.11 from Hope(2006) - CO2 concentration
            v.c_CO2concentration[t]=p.pic_preindustconcCO2+v.exc_excessconcCO2 * v.re_remainCO2[t]/v.re_remainCO2base
        end
    end
end
