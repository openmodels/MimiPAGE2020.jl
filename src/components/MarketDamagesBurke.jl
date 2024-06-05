using Interpolations
using Statistics
include("../utils/country_tools.jl")

@defcomp MarketDamagesBurke begin
    region = Index()
    country = Index()

    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")

    # incoming parameters from Climate
    rtl_realizedtemperature_absolute = Parameter(index=[time, country], unit="degreeC")
    rtl_0_realizedtemperature_absolute = Parameter(index=[country], unit="degreeC")

    # tolerability and impact variables from PAGE damages that Burke damages also require
    rcons_per_cap_SLRRemainConsumption = Parameter(index=[time, country], unit="\$/person")
    rgdp_per_cap_SLRRemainGDP = Parameter(index=[time, country], unit="\$/person")
    save_savingsrate = Parameter(unit="%", default=15.)
    ipow_MarketIncomeFxnExponent = Parameter(default=0.0)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)

    # added impact parameters and variables specifically for Burke damage function
    impf_coeff_lin = Parameter(default=-0.00829990966469437) # rescaled coefficients from Burke
    impf_coeff_quadr = Parameter(default=-0.000500003403703578)
    tcal_burke = Parameter(default=21.) # calibration temperature for the impact function
    nlag_burke = Parameter(default=1.) # Yumashev et al. (2019) allow for one or two lags

    marginal_offset = Variable(index=[time, country])
    i1log_impactlogchange = Variable(index=[time, country]) # intermediate variable for computation

    # impact variables from PAGE damages that Burke damages also require
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_MarketRemainConsumption = Variable(index=[time, country], unit="\$/person")
    rgdp_per_cap_MarketRemainGDP = Variable(index=[time, country], unit="\$/person")
    iref_ImpactatReferenceGDPperCap = Variable(index=[time, country])
    igdp_ImpactatActualGDPperCap = Variable(index=[time, country])

    isat_ImpactinclSaturationandAdaptation = Variable(index=[time,country], unit="\$")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,country], unit="\$/person")

    # Vulnerability-based shifter coefficients
    burkey_draw = Parameter{Int64}()
    gamma0_burkey_intercept = Variable()
    gamma1_burkey_hazard = Variable()
    gamma2_burkey_vulnerability = Variable()
    gamma3_burkey_copinglack = Variable()
    gamma4_burkey_loggdppc = Variable()

    r1_riskindex_hazard = Parameter(index=[time, country])
    r2_riskindex_vulnerability = Parameter(index=[time, country])
    r3_riskindex_copinglack = Parameter(index=[time, country])
    gdp = Parameter(index=[time, country], unit="\$M")
    pop_population = Parameter(index=[time, country], unit="million person")

    function init(pp, vv, dd)
        burkey = CSV.read("../data/burkey-estimates.csv", DataFrame)
        if pp.burkey_draw == -1
            vv.gamma0_burkey_intercept = mean(burkey.Intercept)
            vv.gamma1_burkey_hazard = mean(burkey.HA)
            vv.gamma2_burkey_vulnerability = mean(burkey.VU)
            vv.gamma3_burkey_copinglack = mean(burkey.CC)
            vv.gamma4_burkey_loggdppc = mean(burkey.loggdppc)
        else
            vv.gamma0_burkey_intercept = burkey.Intercept[pp.burkey_draw]
            vv.gamma1_burkey_hazard = burkey.HA[pp.burkey_draw]
            vv.gamma2_burkey_vulnerability = burkey.VU[pp.burkey_draw]
            vv.gamma3_burkey_copinglack = burkey.CC[pp.burkey_draw]
            vv.gamma4_burkey_loggdppc = burkey.loggdppc[pp.burkey_draw]
        end
    end

    function run_timestep(p, v, d, t)

        # Calculate country-level marginal effect difference
        vv.marginal_offset[t, :] = v.gamma0_burkey_intercept .+ v.gamma1_burkey_hazard * log.(p.r1_riskindex_hazard[t, :]) .+ v.gamma2_burkey_vulnerability * log.(p.r2_riskindex_vulnerability[t, :]) .+ v.gamma3_burkey_copinglack * log.(p.r3_riskindex_copinglack[t, :]) .+ v.gamma4_burkey_loggdppc * log.(p.gdp[t, :] ./ p.pop_population[t, :])
        # Translate into a difference in temperatures
        #   deltay = 2 beta1 T
        delta_temp = marginal_offset ./ (2 * p.impf_coeff_quadr)

        for cc in d.country
            # calculate the log change, depending on the number of lags specified
            v.i1log_impactlogchange[t,cc] = p.nlag_burke * (p.impf_coeff_lin  * (p.rtl_realizedtemperature_absolute[t,cc] - p.rtl_0_realizedtemperature_absolute[cc]) +
                                                            p.impf_coeff_quadr * ((p.rtl_realizedtemperature_absolute[t,cc] + delta_temp[cc] - p.tcal_burke)^2 -
                                                                                  (p.rtl_0_realizedtemperature_absolute[cc] + delta_temp[cc] - p.tcal_burke)^2))

            # calculate the impact at focus region GDP p.c.
            v.iref_ImpactatReferenceGDPperCap[t, cc] = 100 * (1 - exp(v.i1log_impactlogchange[t, cc]))

            # calculate impacts at actual GDP
            v.igdp_ImpactatActualGDPperCap[t, cc] = v.iref_ImpactatReferenceGDPperCap[t, cc] *
                (p.rgdp_per_cap_SLRRemainGDP[t, cc] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_MarketIncomeFxnExponent

            # send impacts down a logistic path if saturation threshold is exceeded
            if v.igdp_ImpactatActualGDPperCap[t, cc] < p.isatg_impactfxnsaturation
                v.isat_ImpactinclSaturationandAdaptation[t, cc] = v.igdp_ImpactatActualGDPperCap[t, cc]
            else
                v.isat_ImpactinclSaturationandAdaptation[t, cc] = p.isatg_impactfxnsaturation +
                    ((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) *
                    ((v.igdp_ImpactatActualGDPperCap[t, cc] - p.isatg_impactfxnsaturation) /
                    (((100 - p.save_savingsrate) - p.isatg_impactfxnsaturation) +
                    (v.igdp_ImpactatActualGDPperCap[t, cc] -
                    p.isatg_impactfxnsaturation)))
            end

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t, cc] = (v.isat_ImpactinclSaturationandAdaptation[t, cc] / 100) * p.rgdp_per_cap_SLRRemainGDP[t, cc]
            v.rcons_per_cap_MarketRemainConsumption[t, cc] = p.rcons_per_cap_SLRRemainConsumption[t, cc] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t, cc]
            v.rgdp_per_cap_MarketRemainGDP[t, cc] = v.rcons_per_cap_MarketRemainConsumption[t, cc] / (1 - p.save_savingsrate / 100)
        end

    end
end

function getriskindexes(informs, iso)
    if iso ∈ aggregates
        agginfo = get_aggregateinfo()
        rows = [findfirst(agiso .== informs.ISO) for agiso in agginfo.ISO[agginfo.Aggregate .== iso]]
        rows = rows[rows .!= nothing]
        if length(rows) == 0
            return nothing, nothing, nothing
        end

        r1vals = [mean(informs."HA.2015"[rows]), mean(informs."HA.2020"[rows]), mean(informs."HA.2023"[rows]), mean((informs."HA.2050.Pess"[rows] + informs."HA.2050.Opt"[rows]) / 2), mean((informs."HA.2080.Pess"[rows] + informs."HA.2080.Opt"[rows]) / 2)]
        r2vals = [mean(informs."VU.2015"[rows]), mean(informs."VU.2020"[rows]), mean(informs."VU.2023"[rows])]
        r3vals = [mean(informs."CC.2015"[rows]), mean(informs."CC.2020"[rows]), mean(informs."CC.2023"[rows])]

        return r1vals, r2vals, r3vals
    else
        row = findfirst(informs.ISO .== iso)
        if row == nothing
            return nothing, nothing, nothing
        end

        r1vals = [informs."HA.2015"[row], informs."HA.2020"[row], informs."HA.2023"[row], (informs."HA.2050.Pess"[row] + informs."HA.2050.Opt"[row]) / 2, (informs."HA.2080.Pess"[row] + informs."HA.2080.Opt"[row]) / 2]
        r2vals = [informs."VU.2015"[row], informs."VU.2020"[row], informs."VU.2023"[row]]
        r3vals = [informs."CC.2015"[row], informs."CC.2020"[row], informs."CC.2023"[row]]
    end

    return r1vals, r2vals, r3vals
end

function addmarketdamagesburke(model::Model)
    marketdamagesburke = add_comp!(model, MarketDamagesBurke)

    marketdamagesburke[:model] = model
    marketdamagesburke[:burkey_draw] = -1
    marketdamagesburke[:rtl_0_realizedtemperature_absolute] = (get_countryinfo().Temp1980 + get_countryinfo().Temp2010) / 2

    informs = CSV.read("../data/inform-combined.csv", DataFrame)
    r1 = Matrix{Union{Missing, Float64}}(missing, dim_count(model, :time), dim_count(model, :country))
    r2 = Matrix{Union{Missing, Float64}}(missing, dim_count(model, :time), dim_count(model, :country))
    r3 = Matrix{Union{Missing, Float64}}(missing, dim_count(model, :time), dim_count(model, :country))
    for cc in 1:dim_count(model, :country)
        r1vals, r2vals, r3vals = getriskindexes(informs, dim_keys(model, :country)[cc])
        if r1vals == nothing
            continue
        end
        interp1 = LinearInterpolation([2015, 2020, 2023, 2050, 2080], r1vals, extrapolation_bc=Line())
        r1[:, cc] = interp1(dim_keys(model, :time))

        interp2 = LinearInterpolation([2015, 2020, 2023], r2vals, extrapolation_bc=Flat())
        r2[:, cc] = interp2(dim_keys(model, :time))

        interp3 = LinearInterpolation([2015, 2020, 2023], r3vals, extrapolation_bc=Flat())
        r3[:, cc] = interp3(dim_keys(model, :time))
    end
    r1[:, ismissing.(r1[1, :])] .= [mean(skipmissing(row)) for row in eachrow(r1)]
    r2[:, ismissing.(r2[1, :])] .= [mean(skipmissing(row)) for row in eachrow(r2)]
    r3[:, ismissing.(r3[1, :])] .= [mean(skipmissing(row)) for row in eachrow(r3)]

    marketdamagesburke[:r1_riskindex_hazard] = r1
    marketdamagesburke[:r2_riskindex_vulnerability] = r2
    marketdamagesburke[:r3_riskindex_copinglack] = r3

    return marketdamagesburke
end
