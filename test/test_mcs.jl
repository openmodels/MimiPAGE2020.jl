using Test
using CSVFiles
using DataFrames
using Distributions

regenerate = false # do a large MC run, to regenerate information needed for std. errors
samplesize = 1000 # normal MC sample size (takes ~5 seconds)
confidence = 2.576 # 99% CI by default; use 1.96 to apply a 95% CI, but expect more spurious errors

# Monte Carlo distribution information
# Filled in from a run with regenerate = true
information = Dict(
    :td => Dict(:transform => x -> log(x), :mu => 20.814327104215817, :sigma => 0.7007588482770571),
    :tpc => Dict(:transform => x -> x, :mu => 3.23416123428041e7, :sigma => 6.374797685068551e7),
    :tac => Dict(:transform => x -> log(x), :mu => 14.944386813804241, :sigma => 0.46207147966982504),
    :te => Dict(:transform => x -> log(x), :mu => 20.84214660784536, :sigma => 0.6995498063474193),
    :c_co2concentration => Dict(:transform => x -> x, :mu => 651134.5999874412, :sigma => 46363.450549201516),
    :ft => Dict(:transform => x -> x, :mu => 6.216834969325794, :sigma => 0.4011489912917528),
    :rt_g => Dict(:transform => x -> x, :mu => 4.366704203451731, :sigma => 1.219601225681128),
    :sealevel => Dict(:transform => x -> x, :mu => 3.026419413461323, :sigma => 1.1459316083150264)
)

output_path = joinpath(@__DIR__, "../output")
compare = DataFrame(load(joinpath(@__DIR__, "validationdata/PAGE2020montecarloquantiles.csv")))

if regenerate
    println("Regenerating MC distribution information")

    # Perform a large MC run and extract statistics for std. errors
    do_monte_carlo_runs(100_000, "RCP4.5 & SSP2", output_path)
    df = DataFrame(load(joinpath(output_path, "mimipagemontecarlooutput.csv")))

    for ii in 1:nrow(compare)
        name = Symbol(compare[ii, :Variable_Name])
        if kurtosis(df[!, name]) > 2.9 # exponential distribution
            
            # in PAGE 2009 :tpc was negative across all quantiles so we took log(-x)
            # for the transform, in PAGE2020 they are not all negative so this
            # has been removed but may need to be revisited if we see high kurtosis
            # for :tpc since we cann't take log(negative value)

            # if name == :tpc # negative across all quantiles
                # print("    :$name => Dict(:transform => x -> log(-x), :mu => $(mean(log(-df[df[name] .< 0, name]))), :sigma => $(std(log(-df[df[name] .< 0, name]))))")
            # else
                # print("    :$name => Dict(:transform => x -> log(x), :mu => $(mean(log(df[df[name] .> 0, name]))), :sigma => $(std(log(df[df[name] .> 0, name]))))")
            # end

            print("    :$name => Dict(:transform => x -> log(x), :mu => $(mean(log.(df[df[!, name] .> 0, name]))), :sigma => $(std(log.(df[df[!, name] .> 0, name]))))")
        else
            print("    :$name => Dict(:transform => x -> x, :mu => $(mean(df[!, name])), :sigma => $(std(df[!, name])))")
        end
        if ii != nrow(compare)
            println(",")
        end
    end
else
    println("Performing MC sample")
    # Perform a small MC run
    do_monte_carlo_runs(samplesize, "RCP4.5 & SSP2", output_path)
    df = DataFrame(load(joinpath(output_path, "mimipagemontecarlooutput.csv")))
end

# Compare all known quantiles
for ii in 1:nrow(compare)
    name = Symbol(compare[ii, :Variable_Name])
    transform = information[name][:transform]
    distribution = Normal(information[name][:mu], information[name][:sigma])
    for qval in [.05, .10, .25, .50, .75, .90, .95]
        estimated = transform(quantile(collect(Missings.skipmissing(df[!, name])), qval)) # perform transform *after* quantile, so captures effect of all values
        stderr = sqrt(qval * (1 - qval) / (samplesize * pdf(distribution, estimated)^2))

        expected = transform(compare[ii, Symbol("perc_$(trunc(Int, qval * 100))")])

        # println("$name x $qval: $estimated ≈ $expected rtol=$(ceil(confidence * stderr; digits = -trunc(Int, log10(stderr))))")
        @test estimated ≈ expected rtol = ceil(confidence * stderr; digits=-trunc(Int, log10(stderr)))
    end
end


##
## Used to produce testing files on May 21, 2021 with master
##

# using DataFrames
# using CSV 

# # get quantiles 
# output_path = joinpath(@__DIR__, "../output")
# do_monte_carlo_runs(100_000, "RCP4.5 & SSP2", output_path)
# df_outputs = DataFrame(load(joinpath(output_path, "mimipagemontecarlooutput.csv")))

# # build and save quantiles dataframe
# Variable_Names = [:td, :tpc, :tac, :te, :c_co2concentration, :ft, :rt_g, :sealevel]
# Quantiles_Placeholder = Array{Any}(fill(missing, length(Variable_Names)))
# df_quantiles = DataFrame(Variable_Name = Variable_Names,
#                             perc_5 = Quantiles_Placeholder,
#                             perc_10 = Quantiles_Placeholder,                
#                             perc_25 = Quantiles_Placeholder,
#                             perc_50 = Quantiles_Placeholder,
#                             perc_75 = Quantiles_Placeholder,
#                             perc_90 = Quantiles_Placeholder,
#                             perc_95 = Quantiles_Placeholder)
# quantiles = [5, 10, 25, 50, 75, 90, 95]

# for (i, variable) in enumerate(Variable_Names)
#     _name = Symbol(df_quantiles[i, :Variable_Name])
#     for quant in quantiles
#         df_quantiles[i, Symbol("perc_$(trunc(Int, quant))")] = quantile(collect(Missings.skipmissing(df_outputs[!, _name])), quant/100)
#     end
# end

# CSV.write(joinpath(@__DIR__, "validationdata/PAGE2020montecarloquantiles.csv"), df_quantiles)

# # save a smaller run with n = 1000
# do_monte_carlo_runs(1000, "RCP4.5 & SSP2", output_path)
# df = DataFrame(load(joinpath(output_path, "mimipagemontecarlooutput.csv")))
# CSV.write(joinpath(@__DIR__, "validationdata/mimipagemontecarlooutput.csv"), df)
