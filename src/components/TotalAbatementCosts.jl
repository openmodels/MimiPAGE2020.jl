

@defcomp TotalAbatementCosts begin
    region = Index()
    country = Index()

    model = Parameter{Model}()

    tc_totalcosts_co2 = Parameter(index=[time, country], unit="\$million")
    tc_totalcosts_ch4 = Parameter(index=[time, region], unit="\$million")
    tc_totalcosts_n2o = Parameter(index=[time, region], unit="\$million")
    tc_totalcosts_linear = Parameter(index=[time, region], unit="\$million")
    pop_population = Parameter(index=[time, country], unit="million person")
    pop_population_region = Parameter(index=[time, region], unit="million person")

    tct_totalcosts = Variable(index=[time, country], unit="\$million")
    tct_percap_totalcostspercap = Variable(index=[time, country], unit="\$/person")
    tct_percap_totalcostspercap_region = Variable(index=[time, region], unit="\$/person")

    function run_timestep(p, v, d, t)
        tct_totalcosts_partial_region = p.tc_totalcosts_n2o[t, :] .+ p.tc_totalcosts_ch4[t, :] .+ p.tc_totalcosts_linear[t, :] # $million
        tct_percap_totalcostspercap_partial_region = tct_totalcosts_partial_region ./ p.pop_population_region[t, :] # $/person

        tct_percap_totalcostspercap_partial = regiontocountry(p.model, tct_percap_totalcostspercap_partial_region) # $/person

        for cc in d.country
            v.tct_totalcosts[t, cc] = p.tc_totalcosts_co2[t, cc] + tct_percap_totalcostspercap_partial[cc] * p.pop_population[t, cc] # $million
            v.tct_percap_totalcostspercap[t, cc] = v.tct_totalcosts[t, cc] / p.pop_population[t, cc] # $/person
        end

        v.tct_percap_totalcostspercap_region[t, :] = countrytoregion(p.model, mean, v.tct_percap_totalcostspercap[t, :])
    end
end

function addtotalabatementcosts(model::Model)
    totalabatementcosts = add_comp!(model, TotalAbatementCosts)

    totalabatementcosts[:model] = model

    totalabatementcosts
end
