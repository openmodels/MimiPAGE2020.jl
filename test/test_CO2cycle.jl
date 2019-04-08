
using Test

include("../src/components/CO2cycle.jl")

add_comp!(m, co2cycle)

set_param!(m, :co2cycle, :e_globalCO2emissions, readpagedata(m, "test/validationdata/e_globalCO2emissions.csv"))
set_param!(m, :co2cycle, :y_year,[2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.])#real values
set_param!(m, :co2cycle, :y_year_0, 2015.)#real value
set_param!(m, :co2cycle, :rt_g_globaltemperature, readpagedata(m, "test/validationdata/rt_g_globaltemperature.csv"))
p=load_parameters(m)
set_leftover_params!(m,p) #important for setting left over component values
##running Model
run(m)

asymp = m[:co2cycle, :asymptote_co2_hist]
asymp_compare = readpagedata(m, "test/validationdata/asymp_comp_co2_proj.csv")

@test asymp ≈ asymp_compare rtol=1e-4

renoccff = m[:co2cycle, :renoccf_remainCO2wocc]
renoccff_compare = readpagedata(m, "test/validationdata/re_co2_no_ccff.csv")

@test renoccff ≈ renoccff_compare rtol=1e-4

co2conc = m[:co2cycle,  :c_CO2concentration]
co2conc_compare = readpagedata(m, "test/validationdata/c_co2concentration.csv")

@test co2conc ≈ co2conc_compare rtol=1e-4
