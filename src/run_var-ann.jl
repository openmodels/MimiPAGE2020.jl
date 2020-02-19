using Mimi

# specify model settings
function set_globalbools()
    global use_variability = true

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

#run main_model file
include("main_model_annual.jl")
include("mcs_annual.jl")

scenarios = ["RCP4.5 & SSP2"]

for scenario in scenarios
    model = "PAGE-VAR"
    # define model, default settings: getpage(NDCs scenario, permafrost, no sea-ice, no page09damages)
    feedbacks = true
    if feedbacks
        m = getpage(scenario, true, true)
    else
        m = getpage(scenario, false, false)
    end
    # run model
    run(m)

    # open up Explorer UI, for visual exploration of the variables
    # explore(m)

    samplesize = 50000
    # do general monte carlo simulation
    do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../output", scenario, model))
end




# specify model settings
function set_globalbools()
    global use_variability = false

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

for scenario in scenarios
    model = "PAGE-ANN"
    # define model, default settings: getpage(NDCs scenario, permafrost, no sea-ice, no page09damages)
    feedbacks = true
    if feedbacks
        m = getpage(scenario, true, true)
    else
        m = getpage(scenario, false, false)
    end
    # run model
    run(m)

    # open up Explorer UI, for visual exploration of the variables
    # explore(m)

    samplesize = 50000
    # do general monte carlo simulation
    do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../output", scenario, model))
end
