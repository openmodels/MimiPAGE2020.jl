using Test


m = page_model()
include("../src/components/RCPSSPScenario.jl")
include("../src/components/TotalForcing.jl")

scenario = add_comp!(m, RCPSSPScenario)
totalforcing = add_comp!(m, TotalForcing)

scenario[:ssp] = "rcp85"

totalforcing[:f_CO2forcing] = readpagedata(m,"test/validationdata/f_co2forcing.csv")
totalforcing[:f_CH4forcing] = readpagedata(m,"test/validationdata/f_ch4forcing.csv")
totalforcing[:f_N2Oforcing] = readpagedata(m,"test/validationdata/f_n2oforcing.csv")
totalforcing[:f_lineargasforcing] = readpagedata(m,"test/validationdata/f_LGforcing.csv")
totalforcing[:exf_excessforcing] = scenario[:exf_excessforcing]

run(m)

forcing=m[:TotalForcing, :ft_totalforcing]
forcing_compare=readpagedata(m,"test/validationdata/ft_totalforcing.csv")

@test forcing ≈ forcing_compare rtol=1e-3
