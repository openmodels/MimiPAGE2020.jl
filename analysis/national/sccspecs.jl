include("../../src/main_model.jl")

mcnum = 10000

model = getpage(use_rffsp=true)
run(model)

## Main specification
if !isfile("allscc.csv")
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Alternative preferences
outs = compute_scc(model, year=2020, prefrange=false, seed=20240528, n=mcnum);
CSV.write("allscc-nodrupp.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

## Experiment: Different pulse years
pulseyears = [2030, 2050, 2100]
for pulseyear in pulseyears
    outs = compute_scc(model, year=pulseyear, seed=20240528, n=mcnum);
    CSV.write("allscc-$(pulseyear)-v2.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Different scenarios
scenarios = Dict("ssp126" => "RCP2.6 & SSP1",
                 "ssp245" => "RCP4.5 & SSP2",
                 "ssp585" => "RCP8.5 & SSP5")
for key in keys(scenarios)
    model = getpage(scenarios[key])
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-$(key).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Market damages
damagespecs = ["pageice", "nooffset", "constoffset"] # last case is adaptive (default)
for damagespec in damagespecs
    model = getpage(; use_rffsp=true, config_marketdmg=damagespec)
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-marketdmg-$(damagespec).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Other damage types
otherspecs = ["pageice", "pinational", "pinonmarket", "pislr"] # last case is both national (default)
for otherspec in otherspecs
    model = getpage(use_rffsp=true, config_nonmarketdmg=(otherspec == "pinational" ? "pinational" : (otherspec == "pislr" ? "national" : "pageice")),
                    config_slrdmg=(otherspec == "pinonmarket" || otherspec == "pinational" ? "national" : "pageice"))
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-otherdmg-$(otherspec).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Abatement costs
macspecs = ["pageice"] # DROP "pinational" # last case is national (default)
for macspec in macspecs
    model = getpage(use_rffsp=true, config_abatement=macspec)
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-mac-$(macspec).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Downscaling method
dsmethods = ["pageice"] # DROP "pinational" # last case is mcpr (default)
for dsmethod in dsmethods
    model = getpage(use_rffsp=true, config_downscaling=dsmethod)
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-downscale-$(dsmethod).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Drop subnational scaling
model = getpage(use_rffsp=true, use_subnational=false)
run(model)
outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
CSV.write("allscc-nosubnational.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

## Experiment: Drop trade
model = getpage(use_rffsp=true, use_trade=false)
run(model)
outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
CSV.write("allscc-notrade.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

## Only subsets of damages
for onlydamage in ["nonmarket", "slr", "discont"] # "market",
    if onlydamage == "market"
        model = getpage(use_rffsp=true, config_nonmarketdmg="none", config_slrdmg="none", config_discontinuity="none")
    elseif onlydamage == "nonmarket"
        model = getpage(use_rffsp=true, config_marketdmg="none", config_slrdmg="none", config_discontinuity="none")
    elseif onlydamage == "slr"
        model = getpage(use_rffsp=true, config_marketdmg="none", config_nonmarketdmg="none", config_discontinuity="none")
    elseif onlydamage == "discont"
        model = getpage(use_rffsp=true, config_marketdmg="none", config_nonmarketdmg="none", config_slrdmg="none")
    end
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-onlydmg-$(onlydamage).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end
