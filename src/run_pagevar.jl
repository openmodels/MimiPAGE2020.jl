using Mimi

function set_globalbools()
    global use_variability = true
    global use_annual = true

    # set random seed to have similar variability development in the base and the marginal model.
    # set variability seed.
    if use_variability
        global varseed = rand(1:1000000000000)
    end

    global set_varseed = false

    global use_linear = false
    global use_logburke = false
    global use_logpopulation = false
    global use_logwherepossible = true
end

# set global values for technical configuration options
set_globalbools()

#run main_model file
include("main_model.jl")
include("mcs.jl")
include("compute_scc.jl")

# get/define model, with default settings (i.e. NDCs scenario, permafrost, no sea-ice, use_page09damages)
# m = getpage()
# or alternatively, with different configurations:
# m = getpage("2 degC Target", true, true)
m = getpage("NDCs", true, false)
# run model
run(m)

# get the social cost of carbon
scc = compute_scc(m, year=2020)
println(scc)

# open up Explorer UI, for visual exploration of the variables
# explore(m)


# get the social cost of carbon for the Monte Carlo simulations, for selected quantiles.
# ad-hoc hack to run Monte Carlo simulation for stochastic model.
samplesize = 5000
sccs = zeros(samplesize)
for i in range(1, samplesize)
    sccs[i] = mean(compute_scc_mcs(m, 1, year=2020))
end
sccobs = [quantile(sccs, [.05, .25, .5, .75, .95]); mean(sccs)]
println(sccobs)
