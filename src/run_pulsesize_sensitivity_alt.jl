#########################
# options to choose from:
###
# - "PAGE-ICE"
# - "PAGE-ICE with Growth Effects"
#########################
global sample = 1000
for pulse in list(range(20000., 130000., 5000.))
    global ps = pulse

    include("runmodel.jl")
    # include("runmodel_growth.jl")
    include("runmodel_annual.jl")
    # include("runmodel_variability.jl")
    include("runmodel_ARvariability.jl")
    # include("runmodel_annualGrowth.jl")
    # include("runmodel_annualGrowth_ARvariability.jl")
end
