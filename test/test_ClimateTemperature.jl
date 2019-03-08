using Mimi
using Test

m = page_model()
include("../src/components/ClimateTemperature.jl")

climatetemperature = add_comp!(m, ClimateTemperature)

climatetemperature[:y_year_0] = 2015.
climatetemperature[:y_year] = Mimi.dim_keys(m.md, :time)

climatetemperature[:ft_totalforcing] = readpagedata(m, "test/validationdata/ft_totalforcing.csv")
climatetemperature[:fs_sulfateforcing] = readpagedata(m, "test/validationdata/fs_sulfateforcing.csv")

p = load_parameters(m)
set_leftover_params!(m, p)

##running Model
run(m)

rtl = m[:ClimateTemperature, :rtl_realizedtemperature]
rtl_compare = readpagedata(m, "test/validationdata/rtl_realizedtemperature.csv")

@test rtl ≈ rtl_compare rtol=1e-5

rto = m[:ClimateTemperature, :rto_g_oceantemperature]
rto_compare = readpagedata(m, "test/validationdata/rto_g_oceantemperature.csv")

@test rto ≈ rto_compare rtol=1e-5

