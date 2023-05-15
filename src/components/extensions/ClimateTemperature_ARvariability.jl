using CSV, Distributions, DataFrames

# Load once and make global
arests = CSV.read(joinpath(@__DIR__, "../../../data/other/arestimates.csv"), DataFrame)

@defcomp ClimateTemperature_ARvariability begin

    region = Index()
    year = Index()

    # Basic parameters
    area = Parameter(index=[region], unit="km2")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)
    ampf_amplification = Parameter(index=[region])

    # Initial temperature outputs
    rt_g0_baseglobaltemp = Parameter(unit="degreeC", default=0.9461666666666667) # needed for feedback in CO2 cycle component

    # variability parameters
    tvarorder_arestimatesrows = Parameter(index=[region], unit="none")
    tvarseed_coefficientsrandomseed = Parameter(unit="none")
    tvarerr_g_globaltemperatureerrorvariance = Variable(unit="degreeC^2")
    tvarconst_g_globaltemperatureintercept = Variable(unit="degreeC")
    tvarar_g_globaltemperatureautoreg = Variable(unit="none")
    tvargmst_g_globaltemperaturesmoothdep = Variable(unit="none")
    tvarerr_regionaltemperatureerrorvariance = Variable(index=[region], unit="degreeC^2")
    tvarconst_regionaltemperatureintercept = Variable(index=[region], unit="degreeC")
    tvarar_regionaltemperatureautoreg = Variable(index=[region], unit="none")
    tvargmst_regionaltemperatureglobaldep = Variable(index=[region], unit="none")

    # Unadjusted temperature calculations
    pt_g_preliminarygmst = Parameter(index=[time], unit="degreeC")
    pt_g_preliminarygmst_ann = Variable(index=[year], unit="degreeC")

    # Global outputs
    rt_g_globaltemperature_ann = Variable(index=[year], unit="degreeC")
    rto_g_oceantemperature_ann = Variable(index=[year], unit="degreeC")
    rtl_g_landtemperature_ann = Variable(index=[year], unit="degreeC")

    # Regional outputs
    rtl_realizedtemperature_ann = Variable(index=[year, region], unit="degreeC")

    function init(p, v, d)
        tvarconst, tvarar, tvargmst = tvar_getcoeffs(findfirst(arests[!, :region] .== "global"))
        v.tvarconst_g_globaltemperatureintercept = tvarconst
        v.tvarar_g_globaltemperatureautoreg = tvarar
        v.tvargmst_g_globaltemperaturesmoothdep = tvargmst
        v.tvarerr_g_globaltemperatureerrorvariance = tvar_geterror(findfirst(arests[!, :region] .== "global"))

        tvarconst, tvarar, tvargmst, tvarerr = tvar_getregions(p.tvarorder_arestimatesrows, tvar_getcoeffs)
        v.tvarconst_regionaltemperatureintercept[:] = tvarconst
        v.tvarar_regionaltemperatureautoreg[:] = tvarar
        v.tvargmst_regionaltemperatureglobaldep[:] = tvargmst
        v.tvarerr_regionaltemperatureerrorvariance[:] = tvarerr
        if p.tvarseed_coefficientsrandomseed != 0
            rng = MersenneTwister(trunc(Int, p.tvarseed_coefficientsrandomseed))
            tvarconst, tvarar, tvargmst = rand(rng, tvar_getmvnormal(findfirst(arests[!, :region] .== "global")))
            v.tvarconst_g_globaltemperatureintercept = tvarconst
            v.tvarar_g_globaltemperatureautoreg = tvarar
            v.tvargmst_g_globaltemperaturesmoothdep = tvargmst

            tvarconst, tvarar, tvargmst, tvarerr = tvar_getregions(p.tvarorder_arestimatesrows, rr -> rand(rng, tvar_getmvnormal(rr)))
            v.tvarconst_regionaltemperatureintercept[:] = tvarconst
            v.tvarar_regionaltemperatureautoreg[:] = tvarar
            v.tvargmst_regionaltemperatureglobaldep[:] = tvargmst
        end
    end

    function run_timestep(p, v, d, tt)
        # annual interpolation of the timestep-calculated variables.
        if is_first(tt)
            for annual_year = 2015:gettime(tt) # because p["y_year_0"] does not exist (globally)
                calc_temp(p, v, d, tt, annual_year) # NEW -- introduce function for calulating temperature
            end
        else
            for annual_year = (gettime(tt - 1) + 1):gettime(tt)
                calc_temp(p, v, d, tt, annual_year) # NEW -- use  function for calulating temperature
            end
        end
    end
end

function calc_temp(p, v, d, tt, annual_year)
    # for every year, do the same calculations, but then with the new annual_year variables
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    # linear interpolation between the years of analysis, forward-stepping, up to gettime(tt)
    ## interpolation here is also linear for 2015-2020
    if is_first(tt)
        frac = annual_year - 2015
        fraction_timestep = frac / ((gettime(tt)) - 2015)

        v.pt_g_preliminarygmst_ann[yr] = (p.pt_g_preliminarygmst[tt]) * (fraction_timestep) + p.rt_g0_baseglobaltemp * (1 - fraction_timestep)  # difference_to_next_tt * ratio_to_there
    else
        frac = annual_year - gettime(tt - 1)
        fraction_timestep = frac / ((gettime(tt)) - (gettime(tt - 1))) # check if +1 might also need to feature here.

        v.pt_g_preliminarygmst_ann[yr] = (p.pt_g_preliminarygmst[tt] ) * (fraction_timestep) + p.pt_g_preliminarygmst[tt - 1] * (1 - fraction_timestep) # difference_to_next_tt * ratio_to_there
    end
    # Without surface albedo, just equal
    v.rt_g_globaltemperature_ann[yr] = v.pt_g_preliminarygmst_ann[yr]

    # Adding variability to global temperature
    if use_variability
        g_variationtemp = rand(Normal(0.0, sqrt(v.tvarerr_g_globaltemperatureerrorvariance)))
    else
        g_variationtemp = 0
    end
    if yr == 1
        v.rt_g_globaltemperature_ann[yr] = v.pt_g_preliminarygmst_ann[yr] + g_variationtemp
    else
        ptdiff = v.pt_g_preliminarygmst_ann[yr] - v.pt_g_preliminarygmst_ann[yr - 1]
        v.rt_g_globaltemperature_ann[yr] = v.tvarconst_g_globaltemperatureintercept + v.tvarar_g_globaltemperatureautoreg * (ptdiff + v.rt_g_globaltemperature_ann[yr - 1]) + v.tvargmst_g_globaltemperaturesmoothdep * v.rt_g_globaltemperature_ann[yr] + g_variationtemp
    end

    # Setting regional temperature (uses globally shocked temperature)
    for r in d.region
        if use_variability
            r_variationtemp = rand(Normal(0.0, sqrt(v.tvarerr_regionaltemperatureerrorvariance[r]))) # NEW - with variation
        else
            r_variationtemp = 0 # NEW - no variation
        end
        if yr == 1
            v.rtl_realizedtemperature_ann[yr, r] = v.rt_g_globaltemperature_ann[yr] * p.ampf_amplification[r] + r_variationtemp
        else
	    # Determine correction to conform in expectation to ampf * T_g
            v.rtl_realizedtemperature_ann[yr, r] = (p.ampf_amplification[r] / (v.tvarar_regionaltemperatureautoreg[r] + v.tvargmst_regionaltemperatureglobaldep[r])) * (v.tvarconst_regionaltemperatureintercept[r] + v.tvarar_regionaltemperatureautoreg[r] * (p.ampf_amplification[r] * ptdiff + v.rtl_realizedtemperature_ann[yr - 1, r]) + v.tvargmst_regionaltemperatureglobaldep[r] * v.rt_g_globaltemperature_ann[yr]) + r_variationtemp
        end
    end

    # Land average temperature
    v.rtl_g_landtemperature_ann[yr] = sum(v.rtl_realizedtemperature_ann[yr, :]' .* p.area') / sum(p.area)

    # Ocean average temperature
    v.rto_g_oceantemperature_ann[yr] = (p.area_e_eartharea * v.rt_g_globaltemperature_ann[yr] - sum(p.area) * v.rtl_g_landtemperature_ann[yr]) / (p.area_e_eartharea - sum(p.area))

end

function tvar_getcoeffs(rr::Union{Int64, Int32})
    tvarconst = arests[rr, :intercept][1]
    tvarar = arests[rr, :ar][1]
    tvargmst = arests[rr, :gmst][1]

    tvarconst, tvarar, tvargmst
end

function tvar_geterror(rr::Union{Int64, Int32})
    arests[rr, :varerror][1]
end

function tvar_getmvnormal(rr::Union{Int64, Int32})
    tvarcoeffs = tvar_getcoeffs(rr)

    names = ["intercept", "ar", "gmst"]
    tvarsigma = zeros(3, 3)
    for ii in 1:3
        for jj in 1:3
            tvarsigma[ii, jj] = arests[rr, Symbol("var$(names[ii])*$(names[jj])")][1]
        end
    end

    MvNormal([tvarcoeffs...], tvarsigma)
end

function tvar_getregions(regionorder::Vector{Union{Missing,Float64}}, coeffproc::Function=tvar_getcoeffs)
    tvar_getregions(convert(Vector{Float64}, regionorder), coeffproc)
end

function tvar_getregions(regionorder::Vector{Float64}, coeffproc::Function=tvar_getcoeffs)
    regionorder = convert(Vector{Int64}, regionorder)
    tvar_getregions(regionorder, coeffproc)
end

function tvar_getregions(regionorder::Vector{Int64}, coeffproc::Function=tvar_getcoeffs)
    regionorder = convert(Vector{Int64}, regionorder)
    tvarconst = zeros(length(regionorder))
    tvarar = zeros(length(regionorder))
    tvargmst = zeros(length(regionorder))
    tvarerr = zeros(length(regionorder))
    for rr in 1:length(regionorder)
        tvarconst[rr], tvarar[rr], tvargmst[rr] = coeffproc(regionorder[rr])
        tvarerr[rr] = tvar_geterror(regionorder[rr])
    end

    tvarconst, tvarar, tvargmst, tvarerr
end

function addclimatetemperature_ARvariability(model::Model, use_seaice::Bool)
    climtemp = add_comp!(model, ClimateTemperature_ARvariability)

    region_keys = Mimi.dim_keys(model.md, :region)
    regionmapping = Dict{String,String}("EU" => "eu", "USA" => "usa", "OECD" => "oth", "Africa" => "afr", "China" => "chi+", "SEAsia" => "ind+", "LatAmerica" => "lat", "USSR" => "rus+")

    tvarorder = zeros(Int64, length(region_keys))
    for rr in 1:length(region_keys)
        tvarorder[rr] = findfirst(arests[!, :region] .== regionmapping[region_keys[rr]])
    end
    climtemp[:tvarorder_arestimatesrows] = tvarorder
    climtemp[:tvarseed_coefficientsrandomseed] = 0 # random draw not used

    return climtemp
end
