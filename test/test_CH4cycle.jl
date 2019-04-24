using Test

m = page_model()
include("../src/components/CH4cycle.jl")

addch4cycle(m, true)

set_param!(m, :CH4Cycle, :e_globalCH4emissions, readpagedata(m,"test/validationdata/e_globalCH4emissions.csv"))
set_param!(m, :CH4Cycle, :rtl_g_landtemperature, readpagedata(m,"test/validationdata/rtl_g_landtemperature.csv"))
set_param!(m,:CH4Cycle,:y_year_0,2015.)

p = load_parameters(m)
p["y_year"] = Mimi.dim_keys(m.md, :time)
set_leftover_params!(m, p)

#running Model
run(m)

conc=m[:CH4Cycle,  :c_CH4concentration]
conc_compare=readpagedata(m,"test/validationdata/c_ch4concentration.csv")

@test conc ≈ conc_compare rtol=1e-4
