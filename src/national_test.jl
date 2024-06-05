import Mimi.add_save!
include("main_model.jl")

model = getpage(use_rffsp=true)
run(model)

df = getdataframe(model, :MarketDamagesBurke, :isat_per_cap_ImpactperCapinclSaturationandAdaptation)
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

output_path = "output"
res = run(mcs, model, 1000; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)



outs = compute_scc(model, year=2020, seed=20240528, n=1000);

CSV.write("allscc-nodrupp.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
## CSV.write("allscc-drupp.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

# outs.scc_disaggregated[outs.scc_disaggregated.country .== "KOR", :]

## outs = compute_scc(model, year=2020)
## outs.scc
