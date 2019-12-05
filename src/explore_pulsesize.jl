using Mimi
using DataFrames
using CSV

function set_globalbools()
    global use_variability = true
    global use_annual = true

    # set random seed to have similar variability development in the base and the marginal model.
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
m = getpage("RCP4.5 & SSP2", true, true)
# run model
run(m)

# get the social cost of carbon
# scc = compute_scc(m, year=2020)
# println(scc)

# open up Explorer UI, for visual exploration of the variables
# explore(m)


# get the social cost of carbon for the Monte Carlo simulations, for selected quantiles.
# ad-hoc hack to run Monte Carlo simulation for stochastic model.


samplesize = 50000

testpulses = [2, 5, 10, 15, 20, 25, 50, 75, 100, 125, 150, 175, 200]*1000.
# testpulses = [Int(x) for x in testpulses]

# # some preparations for Julia DataFrame
# testpulsesnames = [string(x) for x in testpulses]
# df_VAR = DataFrame(p2=zeros(samplesize), p4=zeros(samplesize), p6=zeros(samplesize), p8=zeros(samplesize), p10=zeros(samplesize), p15=zeros(samplesize), p20=zeros(samplesize), p25=zeros(samplesize), p50=zeros(samplesize), p100=zeros(samplesize), p200=zeros(samplesize))
# df_ANN = DataFrame(p2=zeros(samplesize), p4=zeros(samplesize), p6=zeros(samplesize), p8=zeros(samplesize), p10=zeros(samplesize), p15=zeros(samplesize), p20=zeros(samplesize), p25=zeros(samplesize), p50=zeros(samplesize), p100=zeros(samplesize), p200=zeros(samplesize))
df_VAR = DataFrame(SCC=Float64[], Pulse=Float64[])
df_ANN = DataFrame(SCC=Float64[], Pulse=Float64[])
df_ICE = DataFrame(SCC=Float64[], Pulse=Float64[])

println("For variability")
for i in range(1,length(testpulses))

    # for ii in range(1, samplesize)
    #     sccs[i, ii] = mean(compute_scc_mcs(m, 1, year=2020, pulse_size = testpulses[i]))
    # end
    sccs = DataFrame(SCC=zeros(samplesize), Pulse=zeros(samplesize))
    sccs[:SCC] = compute_scc_mcs(m, samplesize, year=2020, pulse_size = testpulses[i])
    sccs[:Pulse] = fill(testpulses[i], samplesize)

    # add results to Dataframe
    append!(df_VAR, sccs)

    # print some results just for progress checking
    println("pulse_size = ", testpulses[i])
    println(mean(df_VAR.SCC))
end
# write out results to CSV
CSV.write("C:\\Users\\kikstra\\Documents\\GitHub\\mimi-page-2020.jl\\output\\pagevar_pulsesizetest_50000.csv", df_VAR)


println("For annual, no variability")
for i in range(1,length(testpulses))
    global use_variability = false

    sccs = DataFrame(SCC=zeros(samplesize), Pulse=zeros(samplesize))
    sccs[:SCC] = compute_scc_mcs(m, samplesize, year=2020, pulse_size = testpulses[i])
    sccs[:Pulse] = fill(testpulses[i], samplesize)

    # add results to Dataframe
    append!(df_ANN, sccs)

    # print some results just for progress checking
    println("pulse_size = ", testpulses[i])
    println(mean(df_ANN.SCC))
end
# write out results to CSV
CSV.write("C:\\Users\\kikstra\\Documents\\GitHub\\mimi-page-2020.jl\\output\\pageann_pulsesizetest_50000.csv", df_ANN)


println("For default PAGE-ICE")
for i in range(1,length(testpulses))
    global use_variability = false
    global use_annual = false

    sccs = DataFrame(SCC=zeros(samplesize), Pulse=zeros(samplesize))
    sccs[:SCC] = compute_scc_mcs(m, samplesize, year=2020, pulse_size = testpulses[i])
    sccs[:Pulse] = fill(testpulses[i], samplesize)

    # add results to Dataframe
    append!(df_ICE, sccs)

    # print some results just for progress checking
    println("pulse_size = ", testpulses[i])
    println(mean(df_ICE.SCC))
end
# write out results to CSV
CSV.write("C:\\Users\\kikstra\\Documents\\GitHub\\mimi-page-2020.jl\\output\\pageice_pulsesizetest_50000.csv", df_ICE)
