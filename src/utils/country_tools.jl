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
