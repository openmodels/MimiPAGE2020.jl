using DelimitedFiles

function savepagedata(model::Model, component::Symbol, variable::Symbol, filepath::AbstractString)
    # Handle relative paths
    if filepath[1] ∉ ['.', '/'] && !isfile(filepath)
        filepath = joinpath(@__DIR__, "..", "..", filepath)
    end

    dims = variable_dimensions(model, component, variable)
    open(filepath, "w") do io
        write(io, "# Index: " * join(dims, ", ") * "\n\n")

        if dims == [:region]
            write(io, join(dim_keys(model, :region), ",") * "\n")
            writedlm(io, model[component, variable], ',')
        elseif dims == [:time]
            write(io, join(dim_keys(model, :time), ",") * "\n")
            writedlm(io, model[component, variable], ',')
        elseif dims == [:time, :region]
            writedlm(io, [["year" dim_keys(model, :region)...]; [["$x" for x in dim_keys(model, :time)] model[component, variable]]], ',')
        else
            error("Unknown dimensions in variable $component.$variable.")
        end
    end
end
