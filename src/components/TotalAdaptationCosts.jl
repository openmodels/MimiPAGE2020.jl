@defcomp TotalAdaptationCosts begin
    region = Index()
    country = Index()

    model = Parameter{Model}()

    # Total Adaptation Costs
    pop_population = Parameter(index=[time, country], unit="million person")
    pop_population_region = Parameter(index=[time, region], unit="million person")
    ac_adaptationcosts_economic = Parameter(index=[time, region], unit="\$million")
    ac_adaptationcosts_noneconomic = Parameter(index=[time, region], unit="\$million")
    ac_adaptationcosts_sealevelrise = Parameter(index=[time, country], unit="\$million")

    act_percap_adaptationcosts = Variable(index=[time, country], unit="\$/person")
    act_percap_adaptationcosts_region = Variable(index=[time, region], unit="\$/person")
    act_adaptationcosts_total = Variable(index=[time, country], unit="\$million")

    function run_timestep(p, v, d, t)
        act_adaptationcosts_partial_region = p.ac_adaptationcosts_economic[t, :] .+ p.ac_adaptationcosts_noneconomic[t, :] # $million
        act_percap_adaptationcosts_partial_region = act_adaptationcosts_partial_region ./ p.pop_population_region[t, :] # $/person

        act_percap_adaptationcosts_partial = regiontocountry(p.model, act_percap_adaptationcosts_partial_region) # $/person

        for cc in d.country
            v.act_adaptationcosts_total[t, cc] = p.ac_adaptationcosts_sealevelrise[t, cc] + act_percap_adaptationcosts_partial[cc] * p.pop_population[t, cc] # $million
            v.act_percap_adaptationcosts[t, cc] = v.act_adaptationcosts_total[t, cc] / p.pop_population[t, cc] # $/person
        end

        v.act_percap_adaptationcosts_region[t, :] = countrytoregion(p.model, mean, v.act_percap_adaptationcosts[t, :])
    end
end

function addtotaladaptationcosts(model::Model)
    totaladaptcost = add_comp!(model, TotalAdaptationCosts)

    totaladaptcost[:model] = model

    return totaladaptcost
end
