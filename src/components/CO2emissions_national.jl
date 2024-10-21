@defcomp co2emissions begin
    country = Index()

    baselineemit = Parameter(index=[time, country], unit="MtCO2/year")
    fracabatedcarbon = Parameter(index=[time, country], unit="portion")

    e_countryCO2emissions = Variable(index=[time,country], unit="Mtonne/year")
    e_globalCO2emissions = Variable(index=[time], unit="Mtonne/year")

    function run_timestep(p, v, d, t)

        # eq.4 in Hope (2006) - regional CO2 emissions as % change from baseline
        for cc in d.country
            v.e_countryCO2emissions[t,cc] = p.baselineemit[t,cc] * (1 - p.fracabatedcarbon[t, cc])
        end
        # eq. 5 in Hope (2006) - global CO2 emissions are sum of regional emissions
        v.e_globalCO2emissions[t] = sum(v.e_countryCO2emissions[t,:])
    end
end
