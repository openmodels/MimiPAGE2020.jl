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
global sccpulse_master = 0.             # 0. (default), any other number
global yearpulse_master = 2020          # 2020 (default), any other model year
global gedisc_master = "Yes"             # "No" (default), "Yes"


# run the model
m = getpage()
run(m)

# check for outcome of interest
a = m[:MarketDamagesRegionBayes, :isat_ImpactinclSaturationandAdaptation]
m_no[:GDP, :gedisc_included]
m[:EquityWeighting, :te_totaleffect]
m_no[:EquityWeighting, :te_totaleffect]
