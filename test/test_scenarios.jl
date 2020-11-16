using Test
using CSV, DataFrames

df = CSV.read(joinpath(@__DIR__, "validationdata/allscenarios.csv"), DataFrame, header=false)
rfrow0 = findfirst(x -> !ismissing(x) && x == "RF in 2100", df[!, 1])
gmstrow0 = findfirst(x -> !ismissing(x) && x == "Temp. in 2100", df[!, 1])
slrrow0 = findfirst(x -> !ismissing(x) && x == "SLR in 2100", df[!, 1])
terow0 = findfirst(x -> !ismissing(x) && x == "Total effect NPV", df[!, 1])

for testscen in 2:size(df)[2]
    isdeterm = df[5, testscen] == "Deterministic"

    if !isdeterm
        continue # handle these in test_scenarios_mcs.jl
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

    include("../src/main_model.jl")

    m = getpage(scenario, use_permafrost, use_seaice, econfunc == "PAGE09 Default")
    if !eqweight
        set_param!(m, :EquityWeighting, :equity_proportion, 0.)
    end

    run(m)

    ## This isn't quite the right comparison
    # forcing = m[:TotalForcing, :ft_totalforcing][6]
    # forcing_compare = df[rfrow0 + 3, testscen]
    # @test forcing ≈ forcing_compare rtol=1e-3

    rt_g = m[:ClimateTemperature, :rt_g_globaltemperature][6]
    rt_g_compare = parse(Float64, df[gmstrow0 + 3, testscen])
    @test rt_g ≈ rt_g_compare rtol = 1e-2

    slr = m[:SeaLevelRise,:s_sealevel][6]
    slr_compare = parse(Float64, df[slrrow0 + 3, testscen])
    @test slr ≈ slr_compare rtol = 1e-2

    te = m[:EquityWeighting, :te_totaleffect]
    te_compare = parse(Float64, df[terow0 + 3, testscen])
    @test te ≈ te_compare rtol = 1e4
end
