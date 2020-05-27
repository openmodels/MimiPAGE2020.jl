using Test

# Test that all models run
outdir = joinpath(@__DIR__, "../output")
samplesize = 10
rm(outdir, recursive=true) # NB !!currently cleans out the 'output' folder!!

include("../src/runmodel.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) == 60
rm(outdir, recursive=true)

include("../src/extensions/runmodel_growth.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  4622
rm(outdir, recursive=true)

include("../src/extensions/runmodel_annual.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  132
rm(outdir, recursive=true)

include("../src/extensions/runmodel_variability.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  132
rm(outdir, recursive=true)

include("../src/extensions/runmodel_ARvariability.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  124
rm(outdir, recursive=true)

include("../src/extensions/runmodel_annualGrowth.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  313
rm(outdir, recursive=true)

include("../src/extensions/runmodel_annualGrowth_ARvariability.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) == 313
rm(outdir, recursive=true)

mkdir(outdir)
