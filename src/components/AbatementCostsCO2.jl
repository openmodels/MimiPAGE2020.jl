function price2frac(carbonprice, minp, maxp)
    if maxp == Inf
        max.(0, min.((carbonprice - minp) / maxp, 1))
    else
        max.(0, min.((carbonprice - minp) / (maxp - minp), 1))
    end
end

@defcomp AbatementCostsCO2 begin
    country = Index()

    baselinecarbon = Parameter(index=[time, country], unit="tCO2")
    gdp = Parameter(index=[time, country], unit="\$M")
    carbonprice = Parameter(index=[country], unit="\$2010/tCO2")

    # Decrease in CO2 for a given tax
    ac_0_20_co2 = Parameter(index=[country], unit="tCO2/\$2010")
    ac_20_50_co2 = Parameter(index=[country], unit="tCO2/\$2010")
    ac_50_100_co2 = Parameter(index=[country], unit="tCO2/\$2010")
    ac_100_200_co2 = Parameter(index=[country], unit="tCO2/\$2010")
    ac_200_500_co2 = Parameter(index=[country], unit="tCO2/\$2010")
    ac_500_inf_co2 = Parameter(index=[country], unit="tCO2/\$2010")
    ac_0_20xyear_co2 = Parameter(index=[country], unit="tCO2/\$2010/year")
    ac_20_50xyear_co2 = Parameter(index=[country], unit="tCO2/\$2010/year")
    ac_50_100xyear_co2 = Parameter(index=[country], unit="tCO2/\$2010/year")
    ac_100_200xyear_co2 = Parameter(index=[country], unit="tCO2/\$2010/year")
    ac_200_500xyear_co2 = Parameter(index=[country], unit="tCO2/\$2010/year")
    ac_500_infxyear_co2 = Parameter(index=[country], unit="tCO2/\$2010/year")
    lag_value_co2 = Parameter(index=[country], unit="tCO2")

    # Decrease in GDP for a given tax
    ac_0_20_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_0_20_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_20_50_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_50_100_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_100_200_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_200_500_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_500_inf_gdp = Parameter(index=[country], unit="\$2010/\$2010")
    ac_0_20xyear_gdp = Parameter(index=[country], unit="\$2010/\$2010/year")
    ac_20_50xyear_gdp = Parameter(index=[country], unit="\$2010/\$2010/year")
    ac_50_100xyear_gdp = Parameter(index=[country], unit="\$2010/\$2010/year")
    ac_100_200xyear_gdp = Parameter(index=[country], unit="\$2010/\$2010/year")
    ac_200_500xyear_gdp = Parameter(index=[country], unit="\$2010/\$2010/year")
    ac_500_infxyear_gdp = Parameter(index=[country], unit="\$2010/\$2010/year")
    lag_value_gdp = Parameter(index=[country], unit="\$2010")

    fracabatedcarbon = Variable(index=[time, country], unit="portion") # portion abated
    loggdpcost = Variable(index=[time, country], unit="log diff") # log difference
    tc_totalcost = Variable(index=[time, country], unit="\$million")

    function run_timestep(pp, vv, dd, tt)
        ac_0_20_co2 = pp.ac_0_20_co2 + pp.ac_0_20xyear_co2 * (gettime(tt) - 2000)
        ac_20_50_co2 = pp.ac_20_50_co2 + pp.ac_20_50xyear_co2 * (gettime(tt) - 2000)
        ac_50_100_co2 = pp.ac_50_100_co2 + pp.ac_50_100xyear_co2 * (gettime(tt) - 2000)
        ac_100_200_co2 = pp.ac_100_200_co2 + pp.ac_100_200xyear_co2 * (gettime(tt) - 2000)
        ac_200_500_co2 = pp.ac_200_500_co2 + pp.ac_200_500xyear_co2 * (gettime(tt) - 2000)
        ac_500_inf_co2 = pp.ac_500_inf_co2 + pp.ac_500_infxyear_co2 * (gettime(tt) - 2000)

        rawtonnesabated = ac_0_20_co2 * price2frac(pp.carbonprice, 0, 20) +
            ac_20_50_co2 * price2frac(pp.carbonprice, 20, 50) +
            ac_50_100_co2 * price2frac(pp.carbonprice, 50, 100) +
            ac_100_200_co2 * price2frac(pp.carbonprice, 100, 200) +
            ac_200_500_co2 * price2frac(pp.carbonprice, 200, 500) +
            ac_500_inf_co2 * price2frac(pp.carbonprice, 500, Inf) # tCO2
        rawfractargetabated = -rawabated ./ baselinecarbon[tt,:] # fraction abated
        # Regularize so not over 1 and goes to 1 as p -> inf
        regfractargetabated = rawfractargetabated ./ (exp.(-pp.carbonprice / 500) + rawfractargetabated)

        # Use autoreg factor to approach target
        # delta y = (y_goal - y_t) / tau = y_t+1 - y_t
        #   => y_t+1 = y_goal / tau + (1 - 1 / tau) y_t
        vv.fracabatedcarbon[tt,:] = regfractargetabated ./ pp.lag_value_co2 + (1 - 1 ./ pp.lag_value_co2) * vv.fracabatedcarbon[tt-1,:]

        ac_0_20_gdp = pp.ac_0_20_gdp + pp.ac_0_20xyear_gdp * (2050 - gettime(tt))
        ac_20_50_gdp = pp.ac_20_50_gdp + pp.ac_20_50xyear_gdp * (2050 - gettime(tt))
        ac_50_100_gdp = pp.ac_50_100_gdp + pp.ac_50_100xyear_gdp * (2050 - gettime(tt))
        ac_100_200_gdp = pp.ac_100_200_gdp + pp.ac_100_200xyear_gdp * (2050 - gettime(tt))
        ac_200_500_gdp = pp.ac_200_500_gdp + pp.ac_200_500xyear_gdp * (2050 - gettime(tt))
        ac_500_inf_gdp = pp.ac_500_inf_gdp + pp.ac_500_infxyear_gdp * (2050 - gettime(tt))

        vv.loggdpcost[tt,:] = ac_0_20_gdp * price2frac(pp.carbonprice, 0, 20) +
            ac_20_50_gdp * price2frac(pp.carbonprice, 20, 50) +
            ac_50_100_gdp * price2frac(pp.carbonprice, 50, 100) +
            ac_100_200_gdp * price2frac(pp.carbonprice, 100, 200) +
            ac_200_500_gdp * price2frac(pp.carbonprice, 200, 500) +
            ac_500_inf_gdp * price2frac(pp.carbonprice, 500, Inf) +
            pp.lag_value_gdp .* log(gdp[tt-1,:]) - log(gdp[tt,:]) # log difference

        vv.tc_totalcost[tt,:] = pp.gdp[tt,:] * (1 - exp(vv.loggdpcost[tt,:]))
    end
end

function addabatementcostsco2(model::Model)
    abatementcostscomp = add_comp!(model, AbatementCostsCO2)

    macs = myloadcsv("data/macs.csv")
    macs2 = im_to_i(macs, "iso", "bs", nothing)

    abatementcostscomp[:ac_0_20_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_0-20_co2")
    abatementcostscomp[:ac_20_50_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_20-50_co2")
    abatementcostscomp[:ac_50_100_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_50-100_co2")
    abatementcostscomp[:ac_100_200_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_100-200_co2")
    abatementcostscomp[:ac_200_500_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_200-500_co2")
    abatementcostscomp[:ac_500_inf_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_500-inf_co2")
    abatementcostscomp[:ac_0_20xyear_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_0-20xyear_co2")
    abatementcostscomp[:ac_20_50xyear_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_20-50xyear_co2")
    abatementcostscomp[:ac_50_100xyear_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_50-100xyear_co2")
    abatementcostscomp[:ac_100_200xyear_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_100-200xyear_co2")
    abatementcostscomp[:ac_200_500xyear_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_200-500xyear_co2")
    abatementcostscomp[:ac_500_infxyear_co2] = readcountrydata_i_const(model, macs2, "iso", "ac_500-infxyear_co2")
    abatementcostscomp[:lag_value_co2] = readcountrydata_i_const(model, macs2, "iso", "lag_value_co2")
    abatementcostscomp[:ac_0_20_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_0-20_gdp")
    abatementcostscomp[:ac_20_50_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_20-50_gdp")
    abatementcostscomp[:ac_50_100_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_50-100_gdp")
    abatementcostscomp[:ac_100_200_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_100-200_gdp")
    abatementcostscomp[:ac_200_500_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_200-500_gdp")
    abatementcostscomp[:ac_500_inf_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_500-inf_gdp")
    abatementcostscomp[:ac_0_20xyear_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_0-20xyear_gdp")
    abatementcostscomp[:ac_20_50xyear_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_20-50xyear_gdp")
    abatementcostscomp[:ac_50_100xyear_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_50-100xyear_gdp")
    abatementcostscomp[:ac_100_200xyear_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_100-200xyear_gdp")
    abatementcostscomp[:ac_200_500xyear_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_200-500xyear_gdp")
    abatementcostscomp[:ac_500_infxyear_gdp] = readcountrydata_i_const(model, macs2, "iso", "ac_500-infxyear_gdp")
    abatementcostscomp[:lag_value_gdp] = readcountrydata_i_const(model, macs2, "iso", "lag_value_gdp")

    return abatementcostscomp
end
