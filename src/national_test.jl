include("main_model.jl")

model = getpage()
run(model)

compute_scc(model, year=2020)
