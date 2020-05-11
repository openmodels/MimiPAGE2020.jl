using Mimi
using CSV

include("../src/main_model.jl")

for scenario in ["RCP4.5 & SSP2", "1.5 degC Target", "RCP2.6 & SSP1", "RCP8.5 & SSP5", "RCP8.5 & SSP2"]

    m0 = getpage(scenario, false, false, true; use_page09weights=true, page09_discontinuity=true)  # just updating climate
    m1 = getpage(scenario, false, false, true; page09_discontinuity=true) # update weighting
    m2 = getpage(scenario, false, false, true) # reduced discontinuity
    m3 = getpage(scenario, true, true, true)   # legacy damages
    m4 = getpage(scenario, true, true, false)  # full PAGE-ICE

    samplesize = 50000
    year = 2020
    pulse_size = 75000.

    # Setup of location of final results
    scc_results0 = zeros(samplesize)
    scc_results1 = zeros(samplesize)
    scc_results2 = zeros(samplesize)
    scc_results3 = zeros(samplesize)
    scc_results4 = zeros(samplesize)
    scc_results5 = zeros(samplesize)
    dmg_results0 = zeros(samplesize, 8)
    dmg_results1 = zeros(samplesize, 8)
    dmg_results2 = zeros(samplesize, 8)
    dmg_results3 = zeros(samplesize, 8)
    dmg_results4 = zeros(samplesize, 8)
    dmg_results5 = zeros(samplesize, 8)

    function mc_scc_calculation(sim_inst::SimulationInstance, trialnum::Int, ntimesteps::Int, ignore::Nothing)
        scc_results0[trialnum] = sim_inst.models[1][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results1[trialnum] = sim_inst.models[2][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results2[trialnum] = sim_inst.models[3][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results3[trialnum] = sim_inst.models[3][:EquityWeighting, :tdac_totalimpactandadaptation]
        scc_results4[trialnum] = sim_inst.models[4][:EquityWeighting, :tdac_totalimpactandadaptation]
        scc_results5[trialnum] = sim_inst.models[5][:EquityWeighting, :tdac_totalimpactandadaptation]

        dmg_results0[trialnum, :] = sum(sim_inst.models[1][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[1][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results1[trialnum, :] = sum(sim_inst.models[2][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[2][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results2[trialnum, :] = sum(sim_inst.models[3][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[3][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results3[trialnum, :] = sum(sim_inst.models[3][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[3][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
        dmg_results4[trialnum, :] = sum(sim_inst.models[4][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[4][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
        dmg_results5[trialnum, :] = sum(sim_inst.models[5][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[5][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
    end

    # get simulation
    mcs = getsim()

    mm0 = get_marginal_model(m0, year=year, pulse_size=pulse_size)
    mm1 = get_marginal_model(m1, year=year, pulse_size=pulse_size)
    mm2 = get_marginal_model(m2, year=year, pulse_size=pulse_size)
    mm3 = get_marginal_model(m3, year=year, pulse_size=pulse_size)
    mm4 = get_marginal_model(m4, year=year, pulse_size=pulse_size)

    # Run
    res = run(mcs, [mm0, mm1, mm2, mm3, mm4], samplesize; post_trial_func=mc_scc_calculation)

    results = DataFrame(page09=scc_results0, newwts=scc_results1, redisc=scc_results2, to2300=scc_results3,
                        arctic=scc_results4, burked=scc_results5)

    if scenario == "1.5 degC Target"
        suffix = "deg1p5"
    elseif scenario == "RCP2.6 & SSP1"
        suffix = "ssp126"
    elseif scenario == "RCP4.5 & SSP2"
        suffix = "ssp245"
    elseif scenario == "RCP8.5 & SSP5"
        suffix = "ssp585"
    elseif scenario == "RCP8.5 & SSP2"
        suffix = "ssp285"
    end
    CSV.write("xscc-damages-$suffix.csv", results)

    using Tables
    CSV.write("page09-xreg-$suffix.csv", Tables.table(dmg_results0; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("newwts-xreg-$suffix.csv", Tables.table(dmg_results1; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("redisc-xreg-$suffix.csv", Tables.table(dmg_results2; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("to2300-xreg-$suffix.csv", Tables.table(dmg_results3; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("arctic-xreg-$suffix.csv", Tables.table(dmg_results4; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("burked-xreg-$suffix.csv", Tables.table(dmg_results5; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
end
