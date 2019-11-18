using Mimi

function set_globalbools()
    global use_annual = true
    global use_linear = false
    global use_logburke = true
    global use_logpopulation = false
end

# set global values for technical configuration options
set_globalbools()

#run main_model file
include("main_model.jl")

# get/define model, with default settings (i.e. NDCs scenario, permafrost, no sea-ice, burkedamages)
m = getpage()
# run model
run(m)

# get the social cost of carbon
scc = compute_scc(m, year=2020)
println(scc)

# open up Explorer UI, for visual exploration of the variables
# explore(m)
