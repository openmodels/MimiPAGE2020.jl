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
reset_masterparameters()

# set parameters manually
global modelspec_master = "RegionBayes" # "RegionBayes" (default), "Region", "Burke" or "PAGE09"
global scen_master = "NDCs"             # "NDCs" (default), tbd
global ge_master = 0.05                  # 0.0 (default), any other Float between 0 and 1
global equiw_master = "Yes"             # "Yes" (default), "No", "DFC"
global gdploss_master = "Excl"          # "Excl" (default), "Incl"
global permafr_master = "No"           # "Yes" (default), "No"
global gedisc_master = "Yes"             # "No" (default), "Yes"


# run the model
m = getpage()
run(m)
