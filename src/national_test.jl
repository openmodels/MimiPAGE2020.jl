include("main_model.jl")

model = getpage(use_rffsp=true)
run(model)

outs = compute_scc(model, year=2020, n=10)

outs = compute_scc(model, year=2020)
outs.scc
CSV.write("bycountry.csv", outs.scc_disaggregated)

