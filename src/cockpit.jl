################################################################################
###################### RUN MODELS MANUALLY  ####################################
################################################################################

using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV

include("getpagefunction.jl")
include("utils/mctools.jl")

# set to default
# define a function to reset the master parameters
function reset_masterparameters()
    global modelspec_master = "RegionBayes" # "RegionBayes" (default), "Region", "Burke" or "PAGE09"
    global ge_master = 0.0                  # 0.0 (default), any other Float between 0 and 1
    global equiw_master = "Yes"             # "Yes" (default), "No", "DFC"
    global gdploss_master = "Excl"          # "Excl" (default), "Incl"
    global permafr_master = "Yes"           # "Yes" (default), "No"
    global gedisc_master = "No"             # "No" (default), "Yes", "Only" (feeds only discontinuity impacts into growth rate)

    "All master parameters reset to defaults"
end

# set parameters manually
global modelspec_master = "PAGE09" # "RegionBayes" (default), "Region", "Burke" or "PAGE09"
global scen_master = "NDCs"             # "NDCs" (default), tbd
global ge_master = 1.                  # 0.0 (default), any other Float between 0 and 1
global equiw_master = "Yes"             # "Yes" (default), "No", "DFC"
global gdploss_master = "Incl"          # "Excl" (default), "Incl"
global permafr_master = "Yes"           # "Yes" (default), "No"
global gedisc_master = "Yes"             # "No" (default), "Yes"


# run the model
m = getpage()
run(m)

m[:EquityWeighting, :te_totaleffect]
m[:EquityWeighting, :td_totaldiscountedimpacts]
m[:EquityWeighting, :tac_totaladaptationcosts]
m[:EquityWeighting, :tpc_totalaggregatedcosts]

m[:EquityWeighting, :lgdpe_gdplossexceedingcons]

m[:SLRDamages, :cons_percap_consumption]

a = m[:EquityWeighting, :lgdpe_gdplossexceedingcons] ./ m[:EquityWeighting, :pop_population]
