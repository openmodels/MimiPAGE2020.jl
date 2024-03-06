using CSV, DataFrames
using Memoize

@memoize function get_countrymapping()
    parameter_directory = joinpath(dirname(@__FILE__), "..", "..", "data")
    df = CSV.read(joinpath(parameter_directory, "countryregions.csv"), DataFrame)

    countrymapping = Dict{String, Vector{String}}()
    for region in unique(df.Region)
        countrymapping[region] = df.Code[df.Region .== region]
    end

    countrymapping
end

@memoize function get_countryinfo()
    parameter_directory = joinpath(dirname(@__FILE__), "..", "..", "data")
    CSV.read(joinpath(parameter_directory, "bycountry.csv"), DataFrame)
end

@memoize function get_aggregateinfo()
    parameter_directory = joinpath(dirname(@__FILE__), "..", "..", "data")
    CSV.read(joinpath(parameter_directory, "aggregates.csv"), DataFrame)
end

aggregates = unique(get_aggregateinfo().Aggregate)

function countrytoregion(model::Model, combine::F, bycountry...) where {F <: Function} #, T = eltype(F())}
    countrymapping = get_countrymapping()
    result = []
    countries = dim_keys(model, :country)
    for region in dim_keys(model, :region)
        indexes = [findfirst(country .== countries) for country in countrymapping[region]]
        value = combine([bycountry[jj][indexes] for jj in 1:length(bycountry)]...)
        push!(result, value)
    end

    result
end

function loadparameters_country(model::Model)
    parameters = Dict{Any,Any}()

    df = get_countryinfo()

    parameters[:pop0_initpopulation] = df.Pop2015
    parameters[:gdp0_initgdp] = df.GDP2015
    parameters[:area] = df.LandArea + df.MarineArea

    parameters
end

function getcountryvalue(pageiso, isos, values, aggregator; allowmissing=false)
    if pageiso ∈ aggregates
        agginfo = get_aggregateinfo()
        iis = [findfirst(iso .== isos) for iso in agginfo.ISO[agginfo.Aggregate .== pageiso]]
        iis = iis[iis .!= nothing]
        if length(iis) == 0
            if allowmissing
                missing
            else
                aggregator(values)
            end
        else
            aggregator(values[iis])
        end
    else
        ii = findfirst(pageiso .== isos)
        if ii == nothing
            if allowmissing
                missing
            else
                aggregator(values)
            end
        else
            values[ii]
        end
    end
end

function myloadcsv(filepath::String)
    # Handle relative paths
    if filepath[1] ∉ ['.', '/'] && !isfile(filepath)
        filepath = joinpath(@__DIR__, "..", "..", filepath)
    end

    # Collect information for each year and country
    CSV.read(filepath, DataFrame)
end

function readcountrydata_it_const(filepath::String, isocol, yearcol, getter, aggregator=mean)
    readcountrydata_it_const(myloadcsv(filepath), isocol, yearcol, getter, aggregator=mean)
end

function readcountrydata_it_const(model::Model, df::DataFrame, isocol, yearcol, valuecol::String, aggregator=mean)
    timexcountry = Matrix{Float64}(undef, dim_count(model, :time), dim_count(model, :country))
    for (ii, time) in enumerate(dim_keys(model, :time))
        for (jj, country) in enumerate(dim_keys(model, :country))
            timexcountry[ii, jj] = getcountryvalue(country, df[df[!, yearcol] .== time, isocol],
                                                   df[df[!, yearcol] .== time, valuecol], aggregator)
        end
    end

    timexcountry
end

function readcountrydata_it_const(model::Model, df::DataFrame, isocol, yearcol, row2value::Function, aggregator=mean)
    df.__value__ = zeros(Float64, nrow(df))
    for row in eachrow(df)
        row.__value__ = row2value(row)
    end

    readcountrydata_it_const(df, isocol, yearcol, "__value__", aggregator=mean)
end

function readcountrydata_it_dist(model::Model, filepath, isocol, yearcol, ptestcol, row2dist, uniforms, aggregator=mean)
    df = myloadcsv(filepath)

    # Update columns accounting for uncertainty
    if all(uniforms .== 0)
        df.__value__ = df[!, ptestcol]
    else
        df.__value__ = zeros(Float64, nrow(df))
        for row in eachrow(df)
            dist = row2dist(row)
            ii = findfirst(dim_keys(model, :time) .== row[yearcol])
            jj = findfirst(dim_keys(model, :country) .== row[isocol])
            row.__value__ = quantile(dist, uniforms[ii, jj])
        end
    end

    readcountrydata_it_const(df, isocol, yearcol, "__value__", aggregator=mean)
end

function readcountrydata_im(model::Model, filepath::String, isocol, mccol, mc, valuecol::String, aggregator=mean)
    readcountrydata_im(model, myloadcsv(filepath), isocol, mccol, mc, valuecol, aggregator)
end

function im_to_i(df::DataFrame, isocol, mccol, mc)
    if mc == nothing
        df2 = combine(groupby(df, isocol), names(df)[names(df) .!= isocol] .=> mean)
        for ii in 2:ncol(df)
            rename!(df2, names(df2)[ii] => names(df)[ii])
        end
    else
        df2 = df[df[!, mccol] .== mc, :]
    end

    df2
end

function readcountrydata_i_const(model::Model, df2::DataFrame, isocol, valuecol::String, aggregator=mean)
    # Collect information for country
    [getcountryvalue(country, df2[!, isocol], df2[!, valuecol], aggregator) for country in dim_keys(model, :country)]
end

function readcountrydata_im(model::Model, df::DataFrame, isocol, mccol, mc, valuecol::String, aggregator=mean)
    if mc == nothing
        df2 = combine(groupby(df[!, [isocol, valuecol]], isocol), valuecol => mean)
        rename!(df2, names(df2)[2] => valuecol)
    else
        df2 = df[df[!, mccol] .== mc, :]
    end

    readcountrydata_i_const(model, df2, isocol, valuecol, aggregator)
end

function readcountrydata_im_ft(model::Model, filepath::String, isocol, mccol, mc, row2value::Function, aggregator=mean)
    df = myloadcsv(filepath)
    df2 = im_to_i(df, isocol, mccol, mc)

    # Collect information for each year and country
    timexcountry = Matrix{Float64}(undef, dim_count(model, :time), dim_count(model, :country))
    for (ii, time) in enumerate(dim_keys(model, :time))
        df2.__value__ = zeros(Float64, nrow(df2))
        for row in eachrow(df2)
            row.__value__ = row2value(row, time)
        end

        for (jj, country) in enumerate(dim_keys(model, :country))
            timexcountry[ii, jj] = getcountryvalue(country, df2[!, isocol], df2.__value__, aggregator)
        end
    end

    timexcountry
end
