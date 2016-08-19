using Base.Test
using Mimi

include("../src/TotalForcing.jl")

m = Model()
setindex(m, :time, 10)

totalforcing = addcomponent(m, TotalForcing)

totalforcing[:f_CO2forcing] = ones(10)
totalforcing[:f_CH4forcing] = 2*ones(10)
totalforcing[:f_N2Oforcing] = 4*ones(10)
totalforcing[:f_lineargasforcing] = 8*ones(10)
totalforcing[:exf_excessforcing] = 16*ones(10)

run(m)

@test m[:TotalForcing, :ft_totalforcing] == 31*ones(10)
