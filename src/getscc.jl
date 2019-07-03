using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV

include("getpagefunction.jl")
include("utils/mctools.jl")

# define the model regions in the order that Mimi returns stuff
myregions = ["EU", "US", "OT","EE","CA","IA","AF","LA"]

# define the output directory
dir_output = "C:/Users/nasha/Documents/GitHub/damage-regressions/data/mimi-page-output/"

# create a data frame where SCCs will be stored
df_out = DataFrame(pulse_exp = -999., pulse_year = -999., scc = -999., market_contr = -999.,
                    nonmarket_contr = -999., SLR_contr = -999., disc_contr = -999.,
                    scc_EU = -999.,
                    scc_US = -999.,
                    scc_OT = -999.,
                    scc_EE = -999.,
                    scc_CA = -999.,
                    scc_IA = -999.,
                    scc_AF = -999.,
                    scc_LA = -999.)

# create the years and pulse magnitudes through which will be looped
pulse_year =  [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250]
pulse_exp = [-6.:1:6.;] # from 1T to 1000GT

# loop through different pulse years and magnitudes
for jj_year in pulse_year
    for jj_exp in pulse_exp

        ### PART 1: compute the SCC and its disaggregation over time and regions

        # clear the parameters
        global getscc_womarket = false
        global getscc_wononmarket = false
        global getscc_woSLR = false
        global getscc_wodisc = false

        # set the pulse parameter zero, i.e. no pulse and compute the model
        global scc_pulse = 0
        m_nopulse = getpage()
        run(m_nopulse)

        # create a model with pulse of +1MT CO2 at t = 1
        global scc_pulse = 10^(jj_exp)
        global year_pulse = jj_year
        m_withpulse = getpage()
        run(m_withpulse)

        # get the time step
        ind = findall(x -> x == jj_year, m_nopulse[:co2emissions, :y_year])

        # compute stuff only if the resulting emissions for the models check out
        if m_withpulse[:co2emissions, :e_globalCO2emissions][ind] == m_nopulse[:co2emissions, :e_globalCO2emissions][ind] .+ m_withpulse[:co2emissions, :ep_CO2emissionpulse] && m_withpulse[:co2emissions, :e_globalCO2emissions][ind .+ 1] == m_nopulse[:co2emissions, :e_globalCO2emissions][ind .+ 1]
            # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
            global scc = (m_withpulse[:EquityWeighting, :te_totaleffect] - m_nopulse[:EquityWeighting, :te_totaleffect]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
            # Note: disaggregation does not work as abatement costs are driven by baseline emissions and growth rate, not by levels at time t
            #scc_imp = (m_withpulse[:EquityWeighting, :td_totaldiscountedimpacts] - m_nopulse[:EquityWeighting, :td_totaldiscountedimpacts]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
            #scc_adt = (m_withpulse[:EquityWeighting, :tac_totaladaptationcosts] - m_nopulse[:EquityWeighting, :tac_totaladaptationcosts]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
            #scc_abm = (m_withpulse[:EquityWeighting, :tpc_totalaggregatedcosts] - m_nopulse[:EquityWeighting, :tpc_totalaggregatedcosts]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]

            # disaggregate SCC by region and time
            scc_disaggregated = (m_withpulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                m_nopulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]

            # write out the disaggregated version for selected years
            if jj_exp == 0. && jj_year == 2020.
                writedlm(string(dir_output, "scc_disaggregated_pulse", string(jj_exp), "_year", string(jj_year), ".csv"),
                                         [permutedims(myregions); scc_disaggregated], ",")
            end

            #### PART 2: calculate component contributions to overall SCC by switching them off

            # create a model without the market damages and run with and without pulse
            global getscc_womarket = true
            global scc_pulse = 0
            m_nopulse_womarket = getpage()
            run(m_nopulse_womarket)
            global scc_pulse = 10^(jj_exp)
            m_withpulse_womarket = getpage()
            run(m_withpulse_womarket)
            global getscc_womarket = false

            # model without SLR damages
            global getscc_woSLR = true
            global scc_pulse = 0
            m_nopulse_woSLR = getpage()
            run(m_nopulse_woSLR)
            global scc_pulse = 10^(jj_exp)
            m_withpulse_woSLR = getpage()
            run(m_withpulse_woSLR)
            global getscc_woSLR = false

            # create a model without nonmarket damages
            global getscc_wononmarket = true
            global scc_pulse = 0
            m_nopulse_wononmarket = getpage()
            run(m_nopulse_wononmarket)
            global scc_pulse = 10^(jj_exp)
            m_withpulse_wononmarket = getpage()
            run(m_withpulse_wononmarket)
            global getscc_wononmarket = false

            # without discontinuity
            global getscc_wodisc = true
            global scc_pulse = 0
            m_nopulse_wodisc = getpage()
            run(m_nopulse_wodisc)
            global scc_pulse = 10^(jj_exp)
            m_withpulse_wodisc = getpage()
            run(m_withpulse_wodisc)
            global getscc_wodisc = false


            # repeat the SCC computation for models without market damages
            global scc_womarket = scc - (m_withpulse_womarket[:EquityWeighting, :te_totaleffect] - m_nopulse_womarket[:EquityWeighting, :te_totaleffect]) / m_withpulse_womarket[:co2emissions, :ep_CO2emissionpulse]
            sccchanges_womarket_disaggregated =  (m_withpulse_womarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                    m_nopulse_womarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_womarket[:co2emissions, :ep_CO2emissionpulse] .-
                                    scc_disaggregated
            # repeat the SCC computation for models without nonmarket damages component
            global scc_wononmarket = scc - (m_withpulse_wononmarket[:EquityWeighting, :te_totaleffect] - m_nopulse_wononmarket[:EquityWeighting, :te_totaleffect]) / m_withpulse_wononmarket[:co2emissions, :ep_CO2emissionpulse]
            sccchanges_wononmarket_disaggregated = (m_withpulse_wononmarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                                        m_nopulse_wononmarket[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_wononmarket[:co2emissions, :ep_CO2emissionpulse]  .-
                                                        scc_disaggregated

            # repeat the SCC computation for models without SLR damages
            global scc_woSLR = scc - (m_withpulse_woSLR[:EquityWeighting, :te_totaleffect] - m_nopulse_woSLR[:EquityWeighting, :te_totaleffect]) / m_withpulse_woSLR[:co2emissions, :ep_CO2emissionpulse]
            sccchanges_woSLR_disaggregated = (m_withpulse_woSLR[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                            m_nopulse_woSLR[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_woSLR[:co2emissions, :ep_CO2emissionpulse]  .-
                                            scc_disaggregated

            # repeat the SCC computation for models without the discontinuity component
            global scc_wodisc = scc - (m_withpulse_wodisc[:EquityWeighting, :te_totaleffect] - m_nopulse_wodisc[:EquityWeighting, :te_totaleffect]) / m_withpulse_wodisc[:co2emissions, :ep_CO2emissionpulse]
            sccchanges_wodisc_disaggregated = (m_withpulse_wodisc[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                    m_nopulse_wodisc[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse_wodisc[:co2emissions, :ep_CO2emissionpulse]  .-
                                            scc_disaggregated

            # write the SCC and the contributions from the components into df_out
            push!(df_out, [jj_exp, jj_year, scc, scc_womarket, scc_wononmarket, scc_woSLR, scc_wodisc,
                            sum(scc_disaggregated[:, 1]),
                            sum(scc_disaggregated[:, 2]),
                            sum(scc_disaggregated[:, 3]),
                            sum(scc_disaggregated[:, 4]),
                            sum(scc_disaggregated[:, 5]),
                            sum(scc_disaggregated[:, 6]),
                            sum(scc_disaggregated[:, 7]),
                            sum(scc_disaggregated[:, 8])])

        else
            error("CO2 pulse was not executed correctly. Emissions differ in the second time period or do not have the pre-specified difference in the first.")
        end

    end
end

# remove the first placeholder row
df_out = df_out[df_out[:scc] .!= -999, :]

# export the SCC and its decomposition for all pulse-year pairs into a csv file
CSV.write(string(dir_output, "scc-aggregates.csv"), df_out)
