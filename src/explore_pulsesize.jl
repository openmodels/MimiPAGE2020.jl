using Mimi
using DataFrames
using CSV

function set_globalbools()
    global use_variability = true
    global use_annual = true

    # set random seed to have similar variability development in the base and the marginal model.
    # set variability seed.
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
m = getpage("NDCs", true, false)
# run model
run(m)

# get the social cost of carbon
# scc = compute_scc(m, year=2020)
# println(scc)

# open up Explorer UI, for visual exploration of the variables
# explore(m)


# get the social cost of carbon for the Monte Carlo simulations, for selected quantiles.
# ad-hoc hack to run Monte Carlo simulation for stochastic model.


samplesize = 2000

testpulses = [2, 4, 6, 8, 10, 15, 20, 25, 50, 100, 200]*1000.
# testpulses = [Int(x) for x in testpulses]

# some preparations for Julia DataFrame
testpulsesnames = [string(x) for x in testpulses]
df_VAR = DataFrame(p2=zeros(samplesize), p4=zeros(samplesize), p6=zeros(samplesize), p8=zeros(samplesize), p10=zeros(samplesize), p15=zeros(samplesize), p20=zeros(samplesize), p25=zeros(samplesize), p50=zeros(samplesize), p100=zeros(samplesize), p200=zeros(samplesize))
df_ANN = DataFrame(p2=zeros(samplesize), p4=zeros(samplesize), p6=zeros(samplesize), p8=zeros(samplesize), p10=zeros(samplesize), p15=zeros(samplesize), p20=zeros(samplesize), p25=zeros(samplesize), p50=zeros(samplesize), p100=zeros(samplesize), p200=zeros(samplesize))


println("For variability")
sccs = zeros(length(testpulses), samplesize)
for i in range(1,length(testpulses))

    for ii in range(1, samplesize)
        sccs[i, ii] = mean(compute_scc_mcs(m, 1, year=2020, pulse_size = testpulses[i]))
    end

    # add results to Dataframe
    df_VAR[i] = sccs[i,:]

    # print some results just for progress checking
    println("pulse_size = ", testpulses[i])
    println(mean(sccs[i,:]))
end
# write out results to CSV
CSV.write("C:\\Users\\kikstra\\Documents\\GitHub\\mimi-page-2020.jl\\output\\pagevar_pulsesizetest.csv", df_VAR)


println("For annual, no variability")
sccs = zeros(length(testpulses), samplesize)
for i in range(1,length(testpulses))
    global use_variability = false

    sccs[i,:] = compute_scc_mcs(m, samplesize, year=2020, pulse_size = testpulses[i])

    # add results to Dataframe
    df_ANN[i] = sccs[i,:]

    # print some results just for progress checking
    println("pulse_size = ", testpulses[i])
    println(mean(sccs[i,:]))
end
# write out results to CSV
CSV.write("C:\\Users\\kikstra\\Documents\\GitHub\\mimi-page-2020.jl\\output\\pageann_pulsesizetest.csv", df_ANN)
