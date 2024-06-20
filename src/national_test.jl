import Mimi.add_save!
include("main_model.jl")

model = getpage(use_rffsp=true)
run(model)

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
res = run(mcs, model, 1000; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)

outs = compute_scc(model, year=2020, seed=20240528, n=1000);
CSV.write("allscc-drupp.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

outs = compute_scc(model, year=2020, prefrange=false, seed=20240528, n=1000);
CSV.write("allscc-nodrupp.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

outs = compute_scc(model, year=2050, prefrange=false, seed=20240528, n=1000);
CSV.write("allscc-nodrupp-2050.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

outs = compute_scc(model, year=2100, prefrange=false, seed=20240528, n=1000);
CSV.write("allscc-nodrupp-2100.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

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

# output_path = "output-ssp126"
# Mimi.delete_RV!(mcs, :rffsp_draw)
# res = run(mcs, model, 1000; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)

# model = getpage("1.5 degC Target")
# run(model)

# output_path = "output-1p5"
# res = run(mcs, model, 1000; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)
