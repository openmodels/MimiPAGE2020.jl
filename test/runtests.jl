using Test
using Mimi

function page_model()
    Mimi.reset_compdefs()

    include("../src/utils/load_parameters.jl")
    include("../src/utils/mctools.jl")

    m = Model()

    set_dimension!(m, :time, [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300])
    set_dimension!(m, :region, ["EU", "USA", "OECD", "USSR", "China", "SEAsia", "Africa", "LatAmerica"])

    return m
end

function get_scenario(ii)
    Mimi.reset_compdefs()
    if ii == 1
        return "ndcs", "NDCs", true
    end
    if ii == 2
        return "2c-saf", "2 degC Target", true
    end
end

@testset "mimi-page.jl" begin

include("test_climatemodel.jl") # error
include("test_AbatementCosts.jl") # error
include("test_AdaptationCosts.jl") # works
include("test_CH4cycle.jl") # error
include("test_CH4emissions.jl") # works
include("test_CH4forcing.jl") # works
include("test_ClimateTemperature.jl") # error
include("test_CO2cycle.jl") # error
include("test_CO2emissions.jl") # works
include("test_CO2forcing.jl") # works
include("test_Discontinuity.jl") # works
include("test_EquityWeighting.jl") # error
include("test_GDP.jl") # works
include("test_LGcycle.jl") # works
include("test_LGemissions.jl") # works
include("test_LGforcing.jl") # works
include("test_loadparameters.jl") # works
include("test_mainmodel.jl") # error
include("test_mainmodel_noperm.jl") # works
include("test_MarketDamages.jl") # works
include("test_MarketDamagesBurke.jl") # works
include("test_N2Ocycle.jl") # works
include("test_N2Oemissions.jl") # works
include("test_N2Oforcing.jl") # works
include("test_NonMarketDamages.jl") # works
include("test_Population.jl")
include("test_SeaLevelRise.jl")
include("test_SLRDamages.jl")
include("test_SulphateForcing.jl")
include("test_TotalAbatementCosts.jl")
include("test_TotalAdaptationCosts.jl")
include("test_TotalForcing.jl")
include("test_Permafrost.jl")
#include("test_mcs.jl")
include("contrib/test_taxeffect.jl")

end
