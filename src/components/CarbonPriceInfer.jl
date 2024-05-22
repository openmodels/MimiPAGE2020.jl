using Roots

function price2frac(carbonprice, minp, maxp)
    if maxp == Inf
        max.(0, min.((carbonprice .- minp) ./ maxp, 1))
    else
        max.(0, min.((carbonprice .- minp) ./ (maxp - minp), 1))
    end
end

macs = myloadcsv("data/macs.csv")

@defcomp CarbonPriceInfer begin
    country = Index()
    region = Index()

    model = Parameter{Model}()

    # Driver of abatement costs
    e0_baselineCO2emissions = Parameter(index=[region], unit="Mtonne/year")
    bau_co2emissions = Parameter(index=[time, region], unit="%")
    er_CO2emissionsgrowth = Parameter(index=[time, region], unit="%")

    # Uncertainty parameters
    mac_draw = Parameter{Int64}()

    ## Parameters set by init to MC values

    # Decrease in CO2 for a given tax
    ac_0_20_co2 = Variable(index=[country], unit="MtCO2/\$2010")
    ac_20_50_co2 = Variable(index=[country], unit="MtCO2/\$2010")
    ac_50_100_co2 = Variable(index=[country], unit="MtCO2/\$2010")
    ac_100_200_co2 = Variable(index=[country], unit="MtCO2/\$2010")
    ac_200_500_co2 = Variable(index=[country], unit="MtCO2/\$2010")
    ac_500_inf_co2 = Variable(index=[country], unit="MtCO2/\$2010")
    ac_0_20xyear_co2 = Variable(index=[country], unit="MtCO2/\$2010/year")
    ac_20_50xyear_co2 = Variable(index=[country], unit="MtCO2/\$2010/year")
    ac_50_100xyear_co2 = Variable(index=[country], unit="MtCO2/\$2010/year")
    ac_100_200xyear_co2 = Variable(index=[country], unit="MtCO2/\$2010/year")
    ac_200_500xyear_co2 = Variable(index=[country], unit="MtCO2/\$2010/year")
    ac_500_infxyear_co2 = Variable(index=[country], unit="MtCO2/\$2010/year")

    carbonprice = Variable(index=[time, country], unit="\$2010/tCO2")

    function init(pp, vv, dd)
        if pp.mac_draw == 0
            macs2 = im_to_i(macs, "iso", "bs", nothing)
        else
            macs2 = im_to_i(macs, "iso", "bs", pp.mac_draw)
        end

        vv.ac_0_20_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_0-20_co2")
        vv.ac_20_50_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_20-50_co2")
        vv.ac_50_100_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_50-100_co2")
        vv.ac_100_200_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_100-200_co2")
        vv.ac_200_500_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_200-500_co2")
        vv.ac_500_inf_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_500-inf_co2")
        vv.ac_0_20xyear_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_0-20xyear_co2")
        vv.ac_20_50xyear_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_20-50xyear_co2")
        vv.ac_50_100xyear_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_50-100xyear_co2")
        vv.ac_100_200xyear_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_100-200xyear_co2")
        vv.ac_200_500xyear_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_200-500xyear_co2")
        vv.ac_500_infxyear_co2[:] = readcountrydata_i_const(pp.model, macs2, "iso", "ac_500-infxyear_co2")
    end

    function run_timestep(pp, vv, dd, tt)
        ac_0_20_co2 = vv.ac_0_20_co2 + vv.ac_0_20xyear_co2 * (gettime(tt) - 2000)
        ac_20_50_co2 = vv.ac_20_50_co2 + vv.ac_20_50xyear_co2 * (gettime(tt) - 2000)
        ac_50_100_co2 = vv.ac_50_100_co2 + vv.ac_50_100xyear_co2 * (gettime(tt) - 2000)
        ac_100_200_co2 = vv.ac_100_200_co2 + vv.ac_100_200xyear_co2 * (gettime(tt) - 2000)
        ac_200_500_co2 = vv.ac_200_500_co2 + vv.ac_200_500xyear_co2 * (gettime(tt) - 2000)
        ac_500_inf_co2 = vv.ac_500_inf_co2 + vv.ac_500_infxyear_co2 * (gettime(tt) - 2000)

        geterdiff = function(carbonprice)
            rawtonnesabated = ac_0_20_co2 .* price2frac(carbonprice, 0, 20) +
                ac_20_50_co2 .* price2frac(carbonprice, 20, 50) +
                ac_50_100_co2 .* price2frac(carbonprice, 50, 100) +
                ac_100_200_co2 .* price2frac(carbonprice, 100, 200) +
                ac_200_500_co2 .* price2frac(carbonprice, 200, 500) +
                ac_500_inf_co2 .* price2frac(carbonprice, 500, Inf) # MtCO2

            # Calculate baseline emissions
            baselineemit = pp.e0_baselineCO2emissions .* pp.bau_co2emissions[tt, :] / 100 # Mt

            rawfractargetabated = -sum(rawtonnesabated) / sum(baselineemit) # fraction abated

            return 100 * (1 - rawfractargetabated) - sum(pp.e0_baselineCO2emissions .* pp.er_CO2emissionsgrowth[tt, :]) / sum(baselineemit)
        end

        if geterdiff(0) < 0 # emissions > no-mitigation
            vv.carbonprice[tt, :] .= 0.
        elseif geterdiff(1000) > 0 # emissions < $1000 price
            vv.carbonprice[tt, :] .= 1000. # XXX: Temporary, while improve MACs
        else
            root = find_zero(geterdiff, (0.0, 1000.0), Bisection())
            vv.carbonprice[tt, :] .= root
        end
    end
end

function addcarbonpriceinfer(model::Model)
    carbonpriceinfer = add_comp!(model, CarbonPriceInfer)

    carbonpriceinfer[:model] = model
    carbonpriceinfer[:mac_draw] = 0
    setdistinctparameter(model, :CarbonPriceInfer, :e0_baselineCO2emissions, readpagedata(model, "data/e0_baselineCO2emissions.csv"))

    return carbonpriceinfer
end
