function Input(texttodisplay)
    # function that allows for user input in the CLI
    println(texttodisplay)
    readline()
end

function runpage()
    options = "
    Choose model version to run:
    - 1 PAGE-ICE (10 timestep)
    - 2 PAGE-ICE with Growth Effects (10 timestep)
    - 3 PAGE-ICE (annual)
    - 4 PAGE-ICE with independent Interannual Temperature Variability (annual)
    - 5 PAGE-ICE with autoregressive Interannual Temperature Variability (annual)
    - 6 PAGE-ICE with Growth Effects (annual)
    - 7 PAGE-ICE with Growth Effects and autoregressive Interannual Temperature Variability (annual)

    Input number:
    "

    version = Input(options)

    if isequal(version, "1") || isequal(version, "PAGE-ICE (10 timestep)")
        include("runmodel.jl")
    elseif isequal(version, "2") || isequal(version, "PAGE-ICE with Growth Effects (10 timestep)")
        include("extensions/runmodel_growth.jl")
    elseif isequal(version, "3") || isequal(version, "PAGE-ICE (annual)")
        include("extensions/runmodel_annual.jl")
    elseif isequal(version, "4") || isequal(version, "PAGE-ICE with independent Interannual Temperature Variability (annual)")
        include("extensions/runmodel_variability.jl")
    elseif isequal(version, "5") || isequal(version, "PAGE-ICE with Interannual Temperature Variability with Autoregression (annual)")
        include("extensions/runmodel_ARvariability.jl")
    elseif isequal(version, "6") || isequal(version, "PAGE-ICE with Growth Effects (annual)")
        include("extensions/runmodel_annualGrowth.jl")
    elseif isequal(version, "7") || isequal(version, "PAGE-ICE with Growth Effects and autoregressive Interannual Temperature Variability (annual)")
        include("extensions/runmodel_annualGrowth_ARvariability.jl")
    else
        println("WARNING: No valid model input provided. Please provide a valid model choice")
    end
end

runpage()
