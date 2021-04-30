function calc_totaladaptationcosts(p, v, d, t, annual_year, r)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    v.act_adaptationcosts_total_ann[yr,r] = p.ac_adaptationcosts_economic_ann[yr,r] + p.ac_adaptationcosts_sealevelrise_ann[yr,r] + p.ac_adaptationcosts_noneconomic_ann[yr,r]
    v.act_percap_adaptationcosts_ann[yr,r] = v.act_adaptationcosts_total_ann[yr,r] / p.pop_population_ann[yr,r]
end

@defcomp TotalAdaptationCosts begin
    region = Index()
    year = Index()
    # Total Adaptation Costs
    pop_population = Parameter(index=[time, region], unit="million person")
    ac_adaptationcosts_economic = Parameter(index=[time, region], unit="\$million")
    ac_adaptationcosts_noneconomic = Parameter(index=[time, region], unit="\$million")
    ac_adaptationcosts_sealevelrise = Parameter(index=[time, region], unit="\$million")
    pop_population_ann = Parameter(index=[year, region], unit="million person")
    ac_adaptationcosts_economic_ann = Parameter(index=[year, region], unit="\$million")
    ac_adaptationcosts_noneconomic_ann = Parameter(index=[year, region], unit="\$million")
    ac_adaptationcosts_sealevelrise_ann = Parameter(index=[year, region], unit="\$million")

    act_adaptationcosts_total = Variable(index=[time, region], unit="\$million")
    act_adaptationcosts_total_ann = Variable(index=[year, region], unit="\$million")
    act_percap_adaptationcosts = Variable(index=[time, region], unit="\$/person")
    act_percap_adaptationcosts_ann = Variable(index=[year, region], unit="\$/person")

    function run_timestep(p, v, d, t)

    for r in d.region
        v.act_adaptationcosts_total[t,r] = p.ac_adaptationcosts_economic[t,r] + p.ac_adaptationcosts_sealevelrise[t,r] + p.ac_adaptationcosts_noneconomic[t,r]
        v.act_percap_adaptationcosts[t,r] = v.act_adaptationcosts_total[t,r] / p.pop_population[t,r]


            # calculate  for this specific year
        if is_first(t)
            for annual_year = 2015:(gettime(t))
                calc_totaladaptationcosts(p, v, d, t, annual_year, r)
            end
        else
            for annual_year = (gettime(t - 1) + 1):(gettime(t))
                calc_totaladaptationcosts(p, v, d, t, annual_year, r)
            end
        end

    end
end
end
