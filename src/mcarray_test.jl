include("main_model.jl")

model = getpage(use_rffsp=true)
run(model)

mcs = getsim()
res = run(mcs, model, 100)
