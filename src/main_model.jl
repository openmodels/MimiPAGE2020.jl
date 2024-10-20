using Mimi
using Random

import Random

export getpage

include("utils/load_parameters.jl")
include("utils/mctools.jl")

include("mcs.jl")
include("compute_scc.jl")

include("components/RCPSSPScenario.jl")
include("components/RFFSPScenario.jl")
include("components/CO2emissions_national.jl")
include("components/CO2cycle.jl")
include("components/CO2forcing.jl")
include("components/CH4emissions.jl")
include("components/CH4cycle.jl")
include("components/CH4forcing.jl")
include("components/N2Oemissions.jl")
include("components/N2Ocycle.jl")
include("components/N2Oforcing.jl")
include("components/LGemissions.jl")
include("components/LGcycle.jl")
include("components/LGforcing.jl")
include("components/SulphateForcing.jl")
include("components/TotalForcing.jl")
include("components/extensions/ClimateTemperature_pageice.jl")
include("components/GlobalTemperature.jl")
include("components/RegionTemperature.jl")
include("components/SeaLevelRise.jl")
include("components/GDP.jl")
include("components/extensions/MarketDamagesBurke_regional.jl")
include("components/MarketDamagesBurke.jl")
include("components/extensions/NonMarketDamages_regional.jl")
include("components/NonMarketDamages.jl")
include("components/Discontinuity.jl")
include("components/AdaptationCosts.jl")
include("components/AdaptationCostsSeaLevel.jl")
include("components/extensions/SLRDamages_regional.jl")
include("components/SLRDamages.jl")
include("components/AbatementCostParameters.jl")
include("components/AbatementCosts.jl")
include("components/CarbonPriceInfer.jl")
include("components/AbatementCostsCO2.jl")
include("components/TotalAbatementCosts.jl")
include("components/TotalAdaptationCosts.jl")
include("components/Population.jl")
include("components/TotalCosts.jl")
include("components/CountryLevelNPV.jl")
include("components/EquityWeighting.jl")
include("components/PermafrostSiBCASA.jl")
include("components/PermafrostJULES.jl")
include("components/PermafrostTotal.jl")

include("models/main_model_def.jl")

