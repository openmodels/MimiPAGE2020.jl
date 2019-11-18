using Mimi

function set_globalbools()
    global use_annual = true
    global use_logburke = true
    global use_linear = false
    global use_logpopulation = false
end

set_globalbools()

include("main_model.jl") #run main_model file
m = getpage() # get model, with default settings (for NDCs scenario)
run(m) # run model

explore(m) # open up Explorer UI
