@defcomp co2forcing begin
    c_CO2concentration = Parameter(index=[time], unit="ppbv")
    f0_CO2baseforcing = Parameter(unit="W/m2", default=1.68)
    fslope_CO2forcingslope = Parameter(unit="W/m2", default=5.5)
    c0_baseCO2conc = Parameter(unit="ppbv", default=400859.5833)
    f_CO2forcing = Variable(index=[time], unit="W/m2")

    function run_timestep(p, v, d, t)

        # eq.13 in Hope 2006
        # the max() condition was added to prevent numerical issues due to  non-positive CO2 concentration levels which occurs in 2300 for low-emission scenarios
        # if the growth effects are paired with GDP-emission feedback
        if p.c_CO2concentration[t] > 0
            v.f_CO2forcing[t] = max(0, p.f0_CO2baseforcing + p.fslope_CO2forcingslope * log(p.c_CO2concentration[t] / p.c0_baseCO2conc) )
        else
            v.f_CO2forcing[t] = 0 
        end
    end
end
