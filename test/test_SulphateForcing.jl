using Test


m = page_model()
include("../src/components/RCPSSPScenario.jl")
include("../src/components/SulphateForcing.jl")

scenario = addrcpsspscenario(m, "NDCs")
sulfemit = add_comp!(m, SulphateForcing)

sulfemit[:pse_sulphatevsbase] = scenario[:pse_sulphatevsbase]

p = load_parameters(m)
p["y_year_0"] = 2015.
p["y_year"] = Mimi.dim_keys(m.md, :time)
set_leftover_params!(m, p)

run(m)

forcing=m[:SulphateForcing,:fs_sulphateforcing]
forcing_compare=readpagedata(m,"test/validationdata/fs_sulphateforcing.csv")

@test forcing ≈ forcing_compare rtol=1e-3
