using Mimi
using Test
using CSV

include("../src/mcs.jl")
df = CSV.read(joinpath(@__DIR__, "validationdata/allscenarios.csv"), header = false)
rfrow0 = findfirst(x->!ismissing(x) && x == "RF in 2100", df[!, 1])
gmstrow0 = findfirst(x->!ismissing(x) && x == "Temp. in 2100", df[!, 1])
slrrow0 = findfirst(x->!ismissing(x) && x == "SLR in 2100", df[!, 1])
terow0 = findfirst(x->!ismissing(x) && x == "Total effect NPV", df[!, 1])

mcs = getsim()

for testscen in 2:size(df)[2]
    isdeterm = df[5, testscen] == "Deterministic"

    if isdeterm
        continue # handle these in test_scenarios.jl
    end

    feedback = df[1, testscen]
    scenario = df[2, testscen]
    econfunc = df[3, testscen]
    eqweight = df[4, testscen] == "Equity weighting ON, PTP discounting"

    println(df[1:5, testscen])

    if feedback == "Nonlinear PCF"
        use_permafrost = true
        use_seaice = false
    elseif feedback == "Nonlinear SAF"
        use_permafrost = false
        use_seaice = true
    elseif feedback == "Nonlinear PCF & SAF"
        use_permafrost = true
        use_seaice = true
    else
        println("Unsupported feedback scenario: $feedback")
        @test false # not handled
        continue
    end

    Mimi.reset_compdefs()

    include("../src/main_model.jl")

    m = getpage(scenario, use_permafrost, use_seaice, econfunc == "PAGE09 Default")
    if !eqweight
        set_param!(m, :EquityWeighting, :equity_proportion, 0.)
    end

    # Run a single time
    run(m)

    # Run for MC
    output_path = joinpath(@__DIR__, "../output")
    res = run(mcs, m, 1000; trials_output_filename = joinpath(output_path, "trialdata.csv"), results_output_dir = output_path)

    ## This isn't quite the right comparison
    # forcing = m[:TotalForcing, :ft_totalforcing][6]
    # forcing_compare = df[rfrow0 + 3, testscen]
    # @test forcing ≈ forcing_compare rtol=1e-3

    dfallrt_g = res.results[1][:ClimateTemperature, :rt_g_globaltemperature]
    allrt_g = dfallrt_g[dfallrt_g[:, :time] .== 2100, 2]
    dfallslr = res.results[1][:SeaLevelRise, :s_sealevel]
    allslr = dfallslr[dfallslr[:, :time] .== 2100, 2]
    dfallte = res.results[1][:EquityWeighting, :te_totaleffect]
    allte = dfallte[:, 1]
    for (quant, drow, rtolmult) in [(0.05, 1, 100), (.25, 2, 60), (.5, 3, 30), (.75, 4, 60), (.95, 5, 100)]
        rt_g = quantile(allrt_g, quant)
        rt_g_compare = parse(Float64, df[gmstrow0 + drow, testscen])
        @test rt_g ≈ rt_g_compare rtol = 1e-2 * rtolmult

        slr = quantile(allslr, quant)
        slr_compare = parse(Float64, df[slrrow0 + drow, testscen])
        @test slr ≈ slr_compare rtol = 1e-2 * rtolmult

        te = quantile(allte, quant)
        te_compare = parse(Float64, df[terow0 + drow, testscen])
        @test te ≈ te_compare rtol = 1e4 * rtolmult
    end
end
