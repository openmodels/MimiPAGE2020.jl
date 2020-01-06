using Mimi

function set_globalbools()
    global use_variability = false
    global use_annual = true

    # set random seed to have similar variability development in the base and the marginal model.
    # set variability seed.
    if use_variability
        global varseed = rand(1:1000000000000)
    end

    global use_linear = false
    global use_logburke = false
    global use_logpopulation = false
    global use_logwherepossible = true
end

# set global values for technical configuration options
set_globalbools()

# get main_model file
include("main_model_annual.jl")
include("mcs_annual.jl")

# get/define model, with default settings (i.e. NDCs scenario, permafrost, no sea-ice, use_page09damages)
# m = getpage()
# or alternatively, with different configurations:
# m = getpage("2 degC Target", true, true)
# m = getpage("NDCs", true, false)

# scenario = "RCP2.6 & SSP1"
# scenario = "RCP4.5 & SSP2"
# scenario = "RCP8.5 & SSP5"

for scenario in ["RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    model = "PAGE-ANN"
    m = getpage(scenario, true, true)
    # run model
    run(m)

    # get the social cost of carbon
    scc = compute_scc(m, year=2020)
    println(scc)

    # open up Explorer UI, for visual exploration of the variables
    # explore(m)


    samplesize = 50000
    # get the social cost of carbon for the Monte Carlo simulations, for selected quantiles.
    # sccs = compute_scc_mcs(m, 5000, year=2020)
    # sccobs = [quantile(sccs, [.05, .25, .5, .75, .95]); mean(sccs)]
    # println(sccobs)


    # do general monte carlo simulation
    do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../output", scenario, model))
end
