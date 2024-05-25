include("main_model.jl")

model = getpage()
run(model)

outs = compute_scc(model, year=2020)
CSV.write("bycountry.csv", outs.scc_disaggregated)

findfirst(dim_keys(model, :country) .== "IDN")

df = getdataframe(model, :TotalAbatementCosts, :tct_percap_totalcostspercap)
df[df.country .== "IDN", :]
df = getdataframe(model, :TotalAdaptationCosts, :act_percap_adaptationcosts)
df = getdataframe(model, :CarbonPriceInfer, :carbonprice)
df = getdataframe(model, :CountryLevelNPV, :td_totaldiscountedimpacts)

df = getdataframe(outs.mm.base, :CountryLevelNPV, :td_totaldiscountedimpacts)
df = getdataframe(outs.mm.modified, :CountryLevelNPV, :td_totaldiscountedimpacts)

df = getdataframe(outs.mm.modified, :TotalAbatementCosts, :tct_percap_totalcostspercap)
df = getdataframe(outs.mm.modified, :TotalAdaptationCosts, :act_percap_adaptationcosts)
df = getdataframe(outs.mm.modified, :CountryLevelNPV, :rcons_percap_dis)
df = getdataframe(outs.mm.modified, :MarketDamagesBurke, :rcons_per_cap_MarketRemainConsumption)
df = getdataframe(outs.mm.modified, :MarketDamagesBurke, :rcons_per_cap_SLRRemainConsumption)
df = getdataframe(outs.mm.modified, :SLRDamages, :d_percap_slr)
