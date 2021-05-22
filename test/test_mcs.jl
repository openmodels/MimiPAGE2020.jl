using Test
using CSVFiles
using DataFrames
using Distributions

regenerate = false # do a large MC run, to regenerate information needed for std. errors
samplesize = 1000 # normal MC sample size (takes ~5 seconds)
confidence = 2.576 # 99% CI by default; use 1.96 to apply a 95% CI, but expect more spurious errors

# Monte Carlo distribution information
information = Dict(
    :td => Dict(:transform => x -> log(x), :mu => 20.867456327307856, :sigma => 0.7170848435689282),
    :tpc => Dict(:transform => x -> x, :mu => 3.269855709984657e7, :sigma => 6.399405798915053e7),
    :tac => Dict(:transform => x -> log(x), :mu => 14.949565049913051, :sigma => 0.452568702427104),
    :te => Dict(:transform => x -> log(x), :mu => 20.8942561684838, :sigma => 0.7150629261233239),
    :c_co2concentration => Dict(:transform => x -> x, :mu => 651186.90267267, :sigma => 46249.12698762989),
    :ft => Dict(:transform => x -> x, :mu => 6.21732179204286, :sigma => 0.4003145327410246),
    :rt_g => Dict(:transform => x -> x, :mu => 4.369819586469511, :sigma => 1.2227973526532832),
    :sealevel => Dict(:transform => x -> x, :mu => 3.030064017722661, :sigma => 1.1553309825462488)
)

compare = DataFrame(load(joinpath(@__DIR__, "validationdata/PAGE2020montecarloquantiles.csv")))
output_path = joinpath(@__DIR__, "../output")

if regenerate
    println("Regenerating MC distribution information")

    # Perform a large MC run and extract statistics
    do_monte_carlo_runs(100_000, "RCP4.5 & SSP2", output_path)
    df = DataFrame(load(joinpath(output_path, "mimipagemontecarlooutput.csv")))

    for ii in 1:nrow(compare)
        name = Symbol(compare[ii, :Variable_Name])
        if kurtosis(df[!, name]) > 2.9 # exponential distribution
            if name == :tpc # negative across all quantiles
                print("    :$name => Dict(:transform => x -> log(-x), :mu => $(mean(log.(-df[df[!, name] .< 0, name]))), :sigma => $(std(log.(-df[df[!, name] .< 0, name]))))")
            else
                print("    :$name => Dict(:transform => x -> log(x), :mu => $(mean(log.(df[df[!, name] .> 0, name]))), :sigma => $(std(log.(df[df[!, name] .> 0, name]))))")
            end
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

        # println("$name x $qval: $estimated ≈ $expected rtol=$(ceil(confidence * stderr, -trunc(Int, log10(stderr))))")
        @test estimated ≈ expected rtol = ceil(confidence * stderr; digits=-trunc(Int, log10(stderr)))
    end
end

## Code used to produce PAGE 2020 quantiles from master on May 21, 2021

# using DataFrames
# using CSV 

# output_path = joinpath(@__DIR__, "../output")
# do_monte_carlo_runs(100_000, "RCP4.5 & SSP2", output_path)
# df = DataFrame(load(joinpath(output_path, "mimipagemontecarlooutput.csv")))

# quantiles = DataFrame(load(joinpath(@__DIR__, "validationdata/PAGE09montecarloquantiles.csv")))
# for row in nrow(quantiles)
#     for (i, qval) in enumerate([.05, .10, .25, .50, .75, .90, .95])
#         variable_name = Symbol(quantiles[i, :Variable_Name])
#         new_quantile = quantile(collect(Missings.skipmissing(df[!, col_name])), qval)
#         quantiles[i, Symbol("perc_$(trunc(Int, qval * 100))")] = new_quantile
#     end
# end
# CSV.write(joinpath(@__DIR__, "validationdata/PAGE2020montecarloquantiles.csv"), quantiles)
  