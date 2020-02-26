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

scenario = "RCP4.5 & SSP2"
do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../output"))
