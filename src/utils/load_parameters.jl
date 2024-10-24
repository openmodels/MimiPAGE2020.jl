using DelimitedFiles

function checkregionorder(model::Model, regions, file)
    regionaliases = Dict{AbstractString,Vector{AbstractString}}("EU" => [],
                                                                 "USA" => ["US"],
                                                                 "OECD" => ["OT"],
                                                                 "Africa" => ["AF"],
                                                                 "China" => ["CA"],
                                                                 "SEAsia" => ["IA"],
                                                                 "LatAmerica" => ["LA"],
                                                                 "USSR" => ["EE"])

    for ii in 1:length(regions)
        region_keys = Mimi.dim_keys(model.md, :region)
        if region_keys[ii] != regions[ii] && !in(regions[ii], regionaliases[region_keys[ii]])
            error("Region indices in $file do not match expectations: $(region_keys[ii]) <> $(regions[ii]).")
        end
    end
end

function checktimeorder(model::Model, times, file)
    for ii in 1:length(times)
        if Mimi.time_labels(model)[ii] != times[ii]
            error("Time indices in $file do not match expectations: $(Mimi.time_labels(model)[ii]) <> $(times[ii]).")
        end
    end
end

function readpagedata(model::Union{Model,Nothing}, filepath::AbstractString)
    # Handle relative paths
    if filepath[1] ∉ ['.', '/'] && !isfile(filepath)
        filepath = joinpath(@__DIR__, "..", "..", filepath)
    end

    content = readlines(filepath)

    firstline = chomp(content[1])
    if firstline == "# Index: region"
        data = readdlm(filepath, ',', header=true, comments=true)

        if model != nothing
            # Check that regions are in the right order
            checkregionorder(model, data[1][:, 1], basename(filepath))
        end

        return convert(Vector{Float64}, vec(data[1][:, 2]))
    elseif firstline == "# Index: time"
        data = readdlm(filepath, ',', header=true, comments=true)

        if model != nothing
            # Check that the times are in the right order
            checktimeorder(model, data[1][:, 1], basename(filepath))
        end

        return convert(Vector{Float64}, vec(data[1][:, 2]))
    elseif firstline == "# Index: time, region"
        data = readdlm(filepath, ',', header=true, comments=true)

        if model != nothing
            # Check that both dimension match
            checktimeorder(model, data[1][:, 1], basename(filepath))
            checkregionorder(model, data[2][2:end], basename(filepath))
        end

        return convert(Array{Float64}, data[1][:, 2:end])
    elseif firstline == "# Index: draw"
        data = readdlm(filepath, ',', header=true, comments=true)

        return convert(Vector{Float64}, vec(data[1][:, 2]))
    else
        error("Unknown header in parameter file $filepath.")
    end
end

function load_parameters(model::Model; lowpass::Bool=false)
    parameters = Dict{Any,Any}()

    parameter_directory = joinpath(dirname(@__FILE__), "..", "..", "data")
    for file in filter(q -> splitext(q)[2] == ".csv", readdir(parameter_directory))
        if file in ["bycountry.csv", "countryregions.csv", "burkey-estimates.csv", "inform-combined.csv", "aggregates.csv", "macs.csv", "e0_baselineCO2emissions_country.csv"]
            continue
        end
        parametername = splitext(file)[1]
        filepath = joinpath(parameter_directory, file)

        parameters[parametername] = readpagedata(model, filepath)
    end
    if lowpass
        parameters["ge_empirical_distribution"] = readpagedata(model, joinpath(parameter_directory, "ge_empirical_distribution_lowpass.csv"))
    end
    parameters_country = loadparameters_country(model)
    parameters = merge(parameters, parameters_country)

    return parameters
end
