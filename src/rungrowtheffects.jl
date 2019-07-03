using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV

include("getpagefunction.jl")
include("utils/mctools.jl")

# define the output directory
dir_output = "C:/Users/nasha/Documents/GitHub/damage-regressions/data/mimi-page-output/"

# create a data frame where SCCs will be stored
df_out = DataFrame(ge = -999.,  gdp2300 = -999., te = -999., equityweighting = -999., dfc_feedback = -999,
                    scc = -999., pulse_year = -999, pulse_exp = -999)

# create the growth effects through which will be loooped
ge_range = [0:0.05:1;]
jj_year =  2020 # compute SCC only for 2020 pulses
jj_exp = 0 # 1MT
compute_scc_ge = false # set to true once scc_branch is merged into the growtheffects

# loop through different pulse years and magnitudes
for jj_ge in ge_range
        for jj_equity in [0., 1.]
                for jj_dfcfeedback in [0., 1.]
                        ### PART 1: compute the SCC and its disaggregation over time and regions

                        # train the model without a SCC pulse a
                        #global scc_pulse = 0
                        global ge_master = jj_ge
                        global equity_proportion_master = jj_equity
                        global dfc_feedback_master = jj_dfcfeedback
                        global scc_pulse = 0.
                        global year_pulse = jj_year
                        m_nopulse = getpage()
                        run(m_nopulse)

                        # create a model with pulse of +1MT CO2 at t = 1
                        global scc_pulse = 10^(jj_exp)
                        m_withpulse = getpage()
                        run(m_withpulse)

                        # compute SCC if required
                        if compute_scc_ge

                                # get the time step
                                ind = findall(x -> x == jj_year, m_nopulse[:co2emissions, :y_year])

                                # compute stuff only if the resulting emissions for the models check out
                                if m_withpulse[:co2emissions, :e_globalCO2emissions][ind] == m_nopulse[:co2emissions, :e_globalCO2emissions][ind] .+ m_withpulse[:co2emissions, :ep_CO2emissionpulse] && m_withpulse[:co2emissions, :e_globalCO2emissions][ind .+ 1] == m_nopulse[:co2emissions, :e_globalCO2emissions][ind .+ 1]
                                    # pulse is 10^6 tCO2 and te_totaleffect is measured in million dollars --> no need for normalisation
                                    global scc = (m_withpulse[:EquityWeighting, :te_totaleffect] - m_nopulse[:EquityWeighting, :te_totaleffect]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]
                                    # Note: disaggregation does not work as abatement costs are driven by baseline emissions and growth rate, not by levels at time t

                                    # disaggregate SCC by region and time
                                    scc_disaggregated = (m_withpulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] -
                                                        m_nopulse[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated]) / m_withpulse[:co2emissions, :ep_CO2emissionpulse]

                                    # write out the disaggregated version for selected parameter ranges 
                                    if jj_ge == 0.05 && jj_dfcfeedback == 0.
                                            writedlm(string(dir_output, "scc_disaggregated_pulse", string(jj_exp), "_year", string(jj_year), "_ge", jj_ge,
                                                    "_dfc", jj_dfcfeedback, "_equity", jj_equity, ".csv"),
                                                scc_disaggregated, ",")
                                    end

                                else
                                    error("CO2 pulse was not executed correctly. Emissions differ in the second time period or do not have the pre-specified difference in the first.")
                                end
                        end

                        # write the SCC and the contributions from the components into df_out
                        push!(df_out, [jj_ge,
                                       sum(m_nopulse[:GDP, :gdp][10, :]),
                                       m_nopulse[:EquityWeighting, :te_totaleffect],
                                       jj_equity,
                                       jj_dfcfeedback,
                                       -999, # XX change this once scc computations are merged in
                                       jj_year,
                                       jj_exp])


                        # clean out the parameters
                        global scc = -999.

                end
        end
end

# remove the first placeholder row
df_out = df_out[df_out[:ge] .!= -999, :]

# export the SCC and its decomposition for all pulse-year pairs into a csv file
CSV.write(string(dir_output, "results-by-growtheffects.csv"), df_out)
