include("../../src/main_model.jl")

mcnum = 10 #10000

model = getpage(use_rffsp=true)
run(model)

## Main specification
outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
CSV.write("allscc.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

## Experiment: Alternative preferences
outs = compute_scc(model, year=2020, prefrange=false, seed=20240528, n=mcnum);
CSV.write("allscc-nodrupp.csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))

## Experiment: Different pulse years
pulseyears = [2050, 2100]
for pulseyear in pulseyears
    outs = compute_scc(model, year=pulseyear, seed=20240528, n=mcnum);
    CSV.write("allscc-$(pulseyear).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Different scenarios
scenarios = Dict("ssp126" => "RCP2.6 & SSP1",
                 "ssp245" => "RCP4.5 & SSP2",
                 "ssp585" => "RCP8.5 & SSP5")
for key in keys(scenarios)
    model = getpage(scenario=scenarios[key])
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-$(key).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Market damages
damagespecs = ["pageice", "nooffset", "constoffset"] # last case is adaptive (default)
for damagespec in damagespecs
    model = getpage(marketdmg=damagespec)
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-$(damagespec).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Other damage types
otherspecs = ["pageice", "pinational", "pinonmarket", "pislr"] # last case is both national (default)
for otherspec in otherspecs
    model = getpage(nonmarketdmg=(otherspec == "pinational" ? "pinational" : (otherspec == "pislr" ? "national" : "pageice")),
                    slrdmg=(otherspec == "pinonmarket" || otherspec == "pinational" ? "national" : "pageice"))
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-$(otherspec).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Abatement costs
macspecs = ["pageice"] # DROP "pinational" # last case is national (default)
for macspec in macspecs
    model = getpage(abatement=macspec)
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-$(macspec).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end

## Experiment: Downscaling method
dsmethods = ["pageice"] # DROP "pinational" # last case is mcpr (default)
for dsmethod in dsmethods
    model = getpage(downscaling=dsmethod)
    run(model)
    outs = compute_scc(model, year=2020, seed=20240528, n=mcnum);
    CSV.write("allscc-$(dsmethod).csv", vcat(outs.scc_disaggregated, DataFrame(country="global", td_totaldiscountedimpacts=missing, scc=outs.scc)))
end
