using Mimi

function set_globalbools()
    global use_annual = true
    global use_linear = false
    global use_logburke = false
    global use_logpopulation = false
    global use_logwherepossible = true
end

# set global values for technical configuration options
set_globalbools()

#run main_model file
include("main_model.jl")

# get/define model, with default settings (i.e. NDCs scenario, permafrost, no sea-ice, use_page09damages)
# m = getpage()
# or alternatively, with different configurations:
# m = getpage("2 degC Target", true, true)
# m = getpage("NDCs", true, false)
scenario = "RCP4.5 & SSP2"
model = "PAGE-ANN"
m = getpage(scenario)
# run model
run(m)

# get the social cost of carbon
scc = compute_scc(m, year=2020)
println(scc)

# open up Explorer UI, for visual exploration of the variables
# explore(m)


samplesize = 10000
# get the social cost of carbon for the Monte Carlo simulations, for selected quantiles.
# sccs = compute_scc_mcs(m, 5000, year=2020)
# sccobs = [quantile(sccs, [.05, .25, .5, .75, .95]); mean(sccs)]
# println(sccobs)


# do general monte carlo simulation
do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../output", scenario, model))
