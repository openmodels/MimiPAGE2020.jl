using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random
using StatsBase
using Statistics


samplesize = 50000
scc_year = 2020

include("main_model.jl")

m = getpage()
# run model
run(m)
compute_scc_mcs(m, samplesize; year=scc_year)

for scenario in ["1.5 degC Target", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../output", scenario))
end
