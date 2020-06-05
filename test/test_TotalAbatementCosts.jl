using DataFrames
using Test

for testscen in 1:2
    valdir, scenario, use_permafrost, use_seaice = get_scenario(testscen)
    println(scenario)

    m = page_model()
    include("../src/components/TotalAbatementCosts.jl")

    add_comp!(m, TotalAbatementCosts)

    set_param!(m, :TotalAbatementCosts, :pop_population, readpagedata(m, "test/validationdata/$valdir/pop_population.csv"))
    set_param!(m, :TotalAbatementCosts, :tc_totalcosts_co2, readpagedata(m, "test/validationdata/$valdir/tc_totalcosts_co2.csv"))
    set_param!(m, :TotalAbatementCosts, :tc_totalcosts_ch4, readpagedata(m, "test/validationdata/$valdir/tc_totalcosts_ch4.csv"))
    set_param!(m, :TotalAbatementCosts, :tc_totalcosts_n2o, readpagedata(m, "test/validationdata/$valdir/tc_totalcosts_n2o.csv"))
    set_param!(m, :TotalAbatementCosts, :tc_totalcosts_linear, readpagedata(m, "test/validationdata/$valdir/tc_totalcosts_linear.csv"))

    run(m)

    # Generated data
    abate_cost = m[:TotalAbatementCosts, :tct_totalcosts]
    abate_cost_per_cap = m[:TotalAbatementCosts, :tct_per_cap_totalcostspercap]

    # Recorded data
    cost_compare = readpagedata(m, "test/validationdata/$valdir/tct_totalcosts.csv")
    cost_cap_compare = readpagedata(m, "test/validationdata/$valdir/tct_per_cap_totalcostspercap.csv")

    @test abate_cost ≈ cost_compare rtol=1e-4
    @test abate_cost_per_cap ≈ cost_cap_compare rtol=1e-7
end

