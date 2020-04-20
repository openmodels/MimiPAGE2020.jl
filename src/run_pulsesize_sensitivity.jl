#########################
# options to choose from:
###
# - "PAGE-ICE"
# - "PAGE-ICE with Growth Effects"
#########################
global sample = 50000
for pulse in [2000., 5000., 10000., 15000., 20000., 25000., 50000., 75000., 100000., 125000., 150000., 175000., 200000.]
    global ps = pulse

    include("runmodel.jl")
    # include("runmodel_growth.jl")
    include("runmodel_annual.jl")
    include("runmodel_variability.jl")
    include("runmodel_ARvariability.jl")
    # include("runmodel_annualGrowth.jl")
    # include("runmodel_annualGrowth_ARvariability.jl")
end
