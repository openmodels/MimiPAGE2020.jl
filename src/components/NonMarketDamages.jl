

@defcomp NonMarketDamages begin
    region = Index()

    y_year = Parameter(index=[time], unit="year")

    #parameters
    rtl_realizedtemperature = Parameter(index=[time, region], unit="degreeC")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, region], unit = "\$/person")
    pop_population = Parameter(index=[time, region], unit="million person")
    VSL = Parameter(index=[region], unit="\$/")
    rcons_per_cap_MarketRemainConsumption = Parameter(index=[time, region], unit = "\$/person")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, region], unit = "\$/person")
    save_savingsrate = Parameter(unit= "%", default=15.)
    b0m = Parameter(index=[region])
    b1m = Parameter(index=[region])
    b2m = Parameter(index=[region])
    b3m = Parameter(index=[region])
    b0c = Parameter(index=[region])
    b1c = Parameter(index=[region])
    b2c = Parameter(index=[region])
    b3c = Parameter(index=[region])

     #parameters that are not required but otherwise the code does not run
    impmax_maxtempriseforadaptpolicyNM = Parameter(index=[region], unit= "degreeC")
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC")
    imp_actualreduction = Parameter(index=[time, region], unit= "%")
    isatg_impactfxnsaturation = Parameter(unit="unitless")

    #variables
    deaths = Variable(index=[time,region], unit="person")
    mort_damages = Variable(index=[time, region], unit = "deaths/person")
    mort_impacts = Variable(index=[time, region], unit = "\$/")
    mort_impactspercap = Variable(index=[time, region], unit = "\$/person")
    rcons_per_cap_NonMarketRemainConsumption = Variable(index=[time, region], unit = "\$/person")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, region], unit = "\$/person")

    function run_timestep(p, v, d, t)

        for r in d.region

            v.mort_damages[t,r] = (p.b0m[r]+p.b0c[r])*p.rtl_realizedtemperature[t,r]+(p.b1m[r]+p.b1c[r])*(p.rtl_realizedtemperature[t,r])^2+(p.b2m[r]+p.b2c[r])*p.rtl_realizedtemperature[t,r]*log(p.rgdp_per_cap_MarketRemainGDP[t,r])+(p.b3m[r]+p.b3c[r])*((p.rtl_realizedtemperature[t,r])^2)*log(p.rgdp_per_cap_MarketRemainGDP[t,r])

            v.deaths[t,r] = v.mort_damages[t,r]*p.pop_population[t,r]

            v.mort_impacts[t,r] = v.deaths[t,r]*p.VSL[r]

            v.mort_impactspercap[t,r] = v.mort_impacts[t,r]/p.pop_population[t,r]

            v.rcons_per_cap_NonMarketRemainConsumption[t,r] = p.rcons_per_cap_MarketRemainConsumption[t,r] - v.mort_impactspercap[t,r]
            v.rgdp_per_cap_NonMarketRemainGDP[t,r] = v.rcons_per_cap_NonMarketRemainConsumption[t,r]/(1-p.save_savingsrate/100)

        end
    end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addnonmarketdamages(model::Model)
    nonmarketdamagescomp = add_comp!(model, NonMarketDamages)
    nonmarketdamagescomp[:impmax_maxtempriseforadaptpolicyNM] = readpagedata(model, "data/impmax_noneconomic.csv")
    return nonmarketdamagescomp
end
