#########################
# options to choose from:
###
# - "PAGE-ICE"
# - "PAGE-ICE with Growth Effects"
#########################
function Input(texttodisplay)
    # function that allows for user input in the CLI
    println(texttodisplay)
    readline()
end

function runpage()
    options = "
    Choose model version to run:
    - 1 PAGE-ICE
    - 2 PAGE-ICE with Growth Effects

    Input number:
    "

    version = Input(options)


    if isequal(version, "1") || isequal(version, "PAGE-ICE")
        include("runmodel.jl")
    elseif isequal(version, "2") || isequal(version, "PAGE-ICE with Growth Effects")
        include("runmodel_growth.jl")
    else
        println("WARNING: No valid model input provided. Please provide a valid model choice")
        runpage()
    end
end

runpage()
