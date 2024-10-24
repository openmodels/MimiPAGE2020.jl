import Mimi.add_save!
include("main_model.jl")

mcnum = 10000

model = getpage(use_rffsp=true)
run(model)

model[:EquityWeighting, :td_totaldiscountedimpacts]

df = getdataframe(model, :NonMarketDamages, :isat_per_cap_ImpactperCapinclSaturationandAdaptation)
df[df.country .== "KOR", :]

mcs = getsim()
add_save!(mcs, (:CountryLevelNPV, :wit_percap_equityweightedimpact))
add_save!(mcs, (:CountryLevelNPV, :tct_percap_totalcosts_total))
add_save!(mcs, (:CountryLevelNPV, :act_percap_adaptationcosts))
add_save!(mcs, (:MarketDamagesBurke, :i1log_impactlogchange))
add_save!(mcs, (:MarketDamagesBurke, :isat_per_cap_ImpactperCapinclSaturationandAdaptation))
add_save!(mcs, (:NonMarketDamages, :isat_per_cap_ImpactperCapinclSaturationandAdaptation))
add_save!(mcs, (:RegionTemperature, :rtl_realizedtemperature_absolute))
add_save!(mcs, (:RegionTemperature, :rtl_realizedtemperature_change))
add_save!(mcs, (:SLRDamages, :d_percap_slr))
add_save!(mcs, (:Discontinuity, :isat_per_cap_DiscImpactperCapinclSaturation))

output_path = "output"
res = run(mcs, model, mcnum; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)

model = getpage("RCP2.6 & SSP1")
run(model)
df = getdataframe(model, :CountryLevelNPV, :wit_percap_equityweightedimpact)
CSV.write("wit_percap_equityweightedimpact-ssp126.csv", df)

model = getpage("1.5 degC Target")
run(model)
df = getdataframe(model, :CountryLevelNPV, :wit_percap_equityweightedimpact)
CSV.write("wit_percap_equityweightedimpact-1p5.csv", df)

model = getpage("2 degC Target")
run(model)
df = getdataframe(model, :CountryLevelNPV, :wit_percap_equityweightedimpact)
CSV.write("wit_percap_equityweightedimpact-2p0.csv", df)

model = getpage("2.5 degC Target")
run(model)
df = getdataframe(model, :CountryLevelNPV, :wit_percap_equityweightedimpact)
CSV.write("wit_percap_equityweightedimpact-2p5.csv", df)
