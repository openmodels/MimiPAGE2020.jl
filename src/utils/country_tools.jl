countrymapping = Dict("EU" => ["AFG", "ALA", "ALB", "DZA", "ASM", "AND", "AGO", "AIA", "ATA"], "USA" => ["ATG"], "OECD" => ["ARG"], "USSR" => ["ARM"], "China" => ["ABW"], "SEAsia" => ["AUS"], "Africa" => ["AUT"], "LatAmerica" => ["AZE"]) # TODO: Load mapping from CSV

function countrytoregion(model::Model, combine::F, bycountry...) where {F <: Function} #, T = eltype(F())}
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

    parameters[:pop0_initpopulation] = zeros(dim_count(model, :country)) # TODO: Load data from CSV

    parameters
end
