include("../utils/country_tools.jl")

using StatsBase
using Distributions

df_patterns = CSV.read("../data/climate/patterns.csv", DataFrame)
df_patterns_generic = CSV.read("../data/climate/patterns_generic.csv", DataFrame)

@defcomp RegionTemperature begin
    region = Index()
    country = Index()

    # Basic parameters
    model = Parameter{Model}()
    prcile = Parameter()

    area = Parameter(index=[country], unit="km2")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)
    area_region = Variable(index=[region], unit="km2")

    # Initial temperature outputs
    rt_g0_baseglobaltemp = Parameter(unit="degreeC", default=0.9461666666666667) # needed for feedback in CO2 cycle component # XXX
    rtl_0_baselandtemp = Variable(index=[country], unit="degreeC")
    rtl_g0_baselandtemp = Variable(unit="degreeC") # needed for feedback in CH4 and N2O cycles

    # Set by init
    b0_intercept = Variable(index=[country], unit="degreeC")
    b1_slope = Variable(index=[country])
    rtl_0_realizedtemperature_absolute = Parameter(index=[country], unit="degreeC")
    rtl_0_realizedtemperature_change = Parameter(index=[country], unit="degreeC")

    # Global outputs
    rt_g_globaltemperature = Parameter(index=[time], unit="degreeC")
    rto_g_oceantemperature = Variable(index=[time], unit="degreeC")
    rtl_g_landtemperature = Variable(index=[time], unit="degreeC")

    # Country and region outputs
    rtl_realizedtemperature_absolute = Variable(index=[time, country], unit="degreeC")
    rtl_realizedtemperature_change = Variable(index=[time, country], unit="degreeC")
    rtl_realizedtemperature_region = Variable(index=[time, region], unit="degreeC")

    function init(p, v, d)
        if p.prcile >= 0
            gcm = get_pattern(p.prcile)
            pattern = df_patterns[df_patterns.model .== gcm]
        else
            pattern = df_patterns_generic
        end

        v.b0_intercept[:] = readcountrydata_i_const(p.model, pattern, :ISO, :intercept)
        v.b1_slope[:] = readcountrydata_i_const(p.model, pattern, :ISO, :slope)

        byregion = countrytoregion(p.model, sum, p.area)
        for rr in d.region
            v.area_region[rr] = byregion[rr]
        end

        for cc in d.country
            v.rtl_0_baselandtemp[cc] = v.b0_intercept[cc] + v.b1_slope[cc] * p.rt_g0_baseglobaltemp
        end

        # Equation 21 from Hope (2006): initial global land temperature
        v.rtl_g0_baselandtemp = sum(v.rtl_0_baselandtemp .* p.area) / sum(p.area)
    end

    function run_timestep(p, v, d, tt)
        for cc in d.country
            v.rtl_realizedtemperature_absolute[tt, cc] = v.b0_intercept[cc] + v.b1_slope[cc] * p.rt_g_globaltemperature[tt]
            v.rtl_realizedtemperature_change[tt, cc] = v.rtl_realizedtemperature_absolute[tt, cc] - p.rtl_0_realizedtemperature_absolute[cc] + p.rtl_0_realizedtemperature_change[cc]
        end

        v.rtl_realizedtemperature_region[tt, :] .= countrytoregion(p.model, mean, v.rtl_realizedtemperature_change[tt, :])

        # Land average temperature
        v.rtl_g_landtemperature[tt] = sum(v.rtl_realizedtemperature_change[tt, :]' .* p.area') / sum(p.area)

        # Ocean average temperature
        v.rto_g_oceantemperature[tt] = (p.area_e_eartharea * p.rt_g_globaltemperature[tt] - sum(p.area) * v.rtl_g_landtemperature[tt]) / (p.area_e_eartharea - sum(p.area))
    end
end

df_warmeocs = CSV.read("../data/climate/warmeocs.csv", DataFrame)
df_gendists = CSV.read("../data/climate/gendists.csv", DataFrame)
df_gmstcmip = CSV.read("../data/climate/gmsts.csv", DataFrame)

function get_pattern(prcile)
    row = round(Int64, prcile * (nrow(df_warmeocs) - .01) + .505)

    probs1 = [pdf(Normal(mu, df_gendists.tau[df_gendists.scenario .== "ssp126"][1]),
                  df_warmeocs.ssp126[row]) for mu in df_gmstcmip.warming[df_gmstcmip.scenario .== "ssp126"]];
    probs2 = [pdf(Normal(mu, df_gendists.tau[df_gendists.scenario .== "ssp370"][1]),
                  df_warmeocs.ssp370[row]) for mu in df_gmstcmip.warming[df_gmstcmip.scenario .== "ssp370"]];

    jointprobs = probs1 .* probs2 / sum(probs1 .* probs2)

    pattern = sample(1:length(jointprobs), Weights(jointprobs))

    df_gmstcmip.model[pattern]
end

function addregiontemperature(model::Model)
    climtemp = add_comp!(model, RegionTemperature)

    climtemp[:model] = model
    climtemp[:area] = readcountrydata_i_const(model, get_countryinfo(), :ISO3, :LandArea)
    climtemp[:prcile] = -1 # means, use the generic number
    climtemp[:rtl_0_realizedtemperature_absolute] = (get_countryinfo().Temp1980 + get_countryinfo().Temp2010) / 2
    climtemp[:rtl_0_realizedtemperature_change] = regiontocountry(model, readpagedata(model, "data/rtl_0_realizedtemperature.csv"))

    return climtemp
end
