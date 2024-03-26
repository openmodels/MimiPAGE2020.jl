include("../utils/country_tools.jl")

using StatsBase
using Distributions

df_patterns = CSV.read("../data/climate/patterns.csv", DataFrame)
df_patterns_generic = CSV.read("../data/climate/patterns_generic.csv", DataFrame)

@defcomp RegionTemperature begin
    region = Index()
    country = Index()

    # Basic parameters
    prcile = Parameter()

    area = Parameter(index=[country], unit="km2")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)
    area_region = Variable(index=[region], unit="km2")

    # Initial temperature outputs
    rt_g0_baseglobaltemp = Parameter(unit="degreeC", default=0.9461666666666667) # needed for feedback in CO2 cycle component # XXX
    rtl_0_baselandtemp = Variable(index=[region], unit="degreeC")
    rtl_g0_baselandtemp = Variable(unit="degreeC") # needed for feedback in CH4 and N2O cycles

    # Set by init
    b0_intercept = Variable(index=[country], unit="degreeC")
    b1_slope = Variable(index=[country])

    # Global outputs
    rto_g_oceantemperature = Variable(index=[time], unit="degreeC")
    rtl_g_landtemperature = Variable(index=[time], unit="degreeC")

    # Regional outputs
    rtl_realizedtemperature = Variable(index=[time, country], unit="degreeC")

    function init(p, v, d)
        if pp.prcile >= 0
            model = get_pattern(pp.prcile)
            pattern = df_patterns[df_patterns.model .== model]
        else
            pattern = df_patterns_generic
        end

        vv.b0_intercept = readcountrydata_i_const(model, pattern, :ISO, :intercept)
        vv.b1_slope = readcountrydata_i_const(model, pattern, :ISO, :slope)

        byregion = countrytoregion(model, sum, p.area)
        for rr in d.region
            v.area_region[rr] = byregion[rr]
        end

        for cc in d.country
            v.rtl_0_baselandtemp[tt, cc] = vv.b0_intercept[cc] + vv.b1_slope[cc] * p.rt_g0_baseglobaltemp
        end

        # Equation 21 from Hope (2006): initial global land temperature
        v.rtl_g0_baselandtemp = sum(v.rtl_0_baselandtemp .* p.area) / sum(p.area)
    end

    function run_timestep(p, v, d, tt)
        for cc in d.country
            v.rtl_realizedtemperature[tt, cc] = vv.b0_intercept[cc] + vv.b1_slope[cc] * v.rt_g_globaltemperature[tt]
        end

        # Land average temperature
        v.rtl_g_landtemperature[tt] = sum(v.rtl_realizedtemperature[tt, :]' .* p.area') / sum(p.area)

        # Ocean average temperature
        v.rto_g_oceantemperature[tt] = (p.area_e_eartharea * v.rt_g_globaltemperature[tt] - sum(p.area) * v.rtl_g_landtemperature[tt]) / (p.area_e_eartharea - sum(p.area))
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

    climtemp[:area] = readcountrydata_i_const(model, get_countryinfo(), :ISO3, :LandArea)
    climtemp[:prcile] = -1 # means, use the generic number

    return climtemp
end
