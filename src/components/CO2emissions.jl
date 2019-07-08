@defcomp co2emissions begin
    region=Index()

    e_globalCO2emissions=Variable(index=[time],unit="Mtonne/year")
    e0_baselineCO2emissions=Parameter(index=[region],unit="Mtonne/year")
    e_regionalCO2emissions=Variable(index=[time,region],unit="Mtonne/year")
    er_CO2emissionsgrowth=Parameter(index=[time,region],unit="%")
    ep_CO2emissionpulse = Parameter(unit = "Mtonne/year", default = 0.)
    y_pulse = Parameter(unit = "year", default = 0)
    y_year  = Parameter(index=[time], unit="year")

    function run_timestep(p, v, d, t)

        #eq.4 in Hope (2006) - regional CO2 emissions as % change from baseline
        for r in d.region
            v.e_regionalCO2emissions[t,r]=p.er_CO2emissionsgrowth[t,r]*p.e0_baselineCO2emissions[r]/100
        end
        #eq. 5 in Hope (2006) - global CO2 emissions are sum of regional emissions
        v.e_globalCO2emissions[t]=sum(v.e_regionalCO2emissions[t,:])

        if @isdefined sccpulse_master
            if isa(sccpulse_master, Number) && sccpulse_master >= 0
                p.ep_CO2emissionpulse = sccpulse_master

                if @isdefined yearpulse_master
                    if isa(yearpulse_master, Number) && yearpulse_master in [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250]
                        p.y_pulse = yearpulse_master
                    else
                        error("The parameter yearpulse_master must be one of the model years. Please adjust the parameter")
                    end
                else
                    p.y_pulse = p.y_year[1]
                end
            else
                error("The parameter sccpulse_master must be a non-negative number. Please adjust the parameter")
            end
        end


        if p.y_year[t] == p.y_pulse
            v.e_globalCO2emissions[t] = v.e_globalCO2emissions[t] + p.ep_CO2emissionpulse
        end
    end
end
