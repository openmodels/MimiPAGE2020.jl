using Test

include("../src/components/CO2cycle.jl")

m = page_model()
addco2cycle(m, true)

set_param!(m, :CO2Cycle, :e_globalCO2emissions, readpagedata(m, "test/validationdata/e_globalCO2emissions.csv"))
set_param!(m, :CO2Cycle, :y_year,[2020.,2030.,2040.,2050.,2075.,2100.,2150.,2200.,2250.,2300.])#real values
set_param!(m, :CO2Cycle, :y_year_0, 2015.)#real value
set_param!(m, :CO2Cycle, :rt_g_globaltemperature, readpagedata(m, "test/validationdata/rt_g_globaltemperature.csv"))
p=load_parameters(m)
set_leftover_params!(m,p) #important for setting left over component values
##running Model
run(m)

te = m[:CO2Cycle, :te_totalemissions]
te_compare = readpagedata(m, "test/validationdata/total_e_co2.csv")
@test te ≈ te_compare rtol=1e-4

asymp = m[:CO2Cycle, :asymptote_co2_proj]
asymp_compare = readpagedata(m, "test/validationdata/asymp_comp_co2_proj.csv")
@test asymp ≈ asymp_compare rtol=1e-4

oceanlong = m[:CO2Cycle, :ocean_long_uptake_component_proj]
oceanlong_compare = readpagedata(m, "test/validationdata/ocean_long_comp_co2_proj.csv")
@test oceanlong ≈ oceanlong_compare rtol=1e-4

renoccff = m[:CO2Cycle, :renoccf_remainCO2wocc]
renoccff_compare = readpagedata(m, "test/validationdata/re_co2_no_ccff.csv")
@test renoccff ≈ renoccff_compare rtol=1e-4

co2conc = m[:CO2Cycle,  :c_CO2concentration]
co2conc_compare = readpagedata(m, "test/validationdata/c_co2concentration.csv")

@test co2conc ≈ co2conc_compare rtol=1e-4
