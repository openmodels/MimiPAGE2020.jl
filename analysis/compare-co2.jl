using CSV

include("../src/climate_model.jl")

alldf_clim = nothing
for scenario in ["RCP1.9 & SSP1", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    mm = climatemodel(scenario)
    run(mm)
    df = getdataframe(mm, :co2emissions, :e_globalCO2emissions)
    df[!, :scenario] .= scenario
    if alldf_clim == nothing
        alldf_clim = df
    else
        alldf_clim = [alldf_clim; df]
    end
end

# CSV.write("old-co2.csv", alldf_clim)

include("../src/main_model.jl")

alldf_main = nothing
for scenario in ["RCP1.9 & SSP1", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    mm = getpage(scenario)
    run(mm)
    df = getdataframe(mm, :co2emissions, :e_globalCO2emissions)
    df[!, :scenario] .= scenario
    cprice = mean(mm[:CarbonPriceInfer, :carbonprice], dims=2)
    df[!, :cprice] .= cprice
    if alldf_main == nothing
        alldf_main = df
    else
        alldf_main = [alldf_main; df]
    end
end

# CSV.write("new-co2.csv", alldf_main)

using Plots

scatter(alldf_clim.e_globalCO2emissions[alldf_clim.time .== 2020], alldf_main.e_globalCO2emissions[alldf_main.time .== 2020])
scatter(alldf_clim.e_globalCO2emissions[alldf_clim.time .== 2100], alldf_main.e_globalCO2emissions[alldf_main.time .== 2100])
scatter(alldf_clim.e_globalCO2emissions[(alldf_clim.e_globalCO2emissions .> 0) .& (alldf_main.e_globalCO2emissions .> 0)], alldf_main.e_globalCO2emissions[(alldf_clim.e_globalCO2emissions .> 0) .& (alldf_main.e_globalCO2emissions .> 0)])
hcat(alldf_clim[(alldf_clim.e_globalCO2emissions .<= 0) .| (alldf_main.e_globalCO2emissions .<= 0), :], alldf_main[(alldf_clim.e_globalCO2emissions .<= 0) .| (alldf_main.e_globalCO2emissions .<= 0), :], makeunique=true)

scatter(alldf_clim.e_globalCO2emissions, alldf_main.e_globalCO2emissions, markercolor=alldf_clim.scenario, label=nothing, xlabel="Regional emissions reductions", ylabel="Country-level response to carbon price")

pp = scatter(alldf_clim.e_globalCO2emissions[alldf_clim.scenario .== "RCP1.9 & SSP1"], alldf_main.e_globalCO2emissions[alldf_clim.scenario .== "RCP1.9 & SSP1"], label="RCP1.9 & SSP1", xlabel="Regional emissions reductions", ylabel="Country-level response to carbon price")
scatter!(pp, alldf_clim.e_globalCO2emissions[alldf_clim.scenario .== "RCP2.6 & SSP1"], alldf_main.e_globalCO2emissions[alldf_clim.scenario .== "RCP2.6 & SSP1"], label="RCP2.6 & SSP1", xlabel="Regional emissions reductions", ylabel="Country-level response to carbon price")
scatter!(pp, alldf_clim.e_globalCO2emissions[alldf_clim.scenario .== "RCP4.5 & SSP2"], alldf_main.e_globalCO2emissions[alldf_clim.scenario .== "RCP4.5 & SSP2"], label="RCP4.5 & SSP2", xlabel="Regional emissions reductions", ylabel="Country-level response to carbon price")
scatter!(pp, alldf_clim.e_globalCO2emissions[alldf_clim.scenario .== "RCP8.5 & SSP5"], alldf_main.e_globalCO2emissions[alldf_clim.scenario .== "RCP8.5 & SSP5"], label="RCP8.5 & SSP5", xlabel="Regional emissions reductions", ylabel="Country-level response to carbon price")
savefig("compare-co2.pdf")
