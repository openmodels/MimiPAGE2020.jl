@defcomp TotalAdaptationCosts_annual begin
    region = Index()
    year = Index()

    # Total Adaptation Costs
    pop_population_region_ann = Parameter(index=[year, region], unit="million person")
    ac_adaptationcosts_economic_ann = Parameter(index=[year, region], unit="\$million")
    ac_adaptationcosts_noneconomic_ann = Parameter(index=[year, region], unit="\$million")
    ac_adaptationcosts_sealevelrise_ann = Parameter(index=[year, region], unit="\$million")

    act_adaptationcosts_total_ann = Variable(index=[year, region], unit="\$million")
    act_percap_adaptationcosts_ann = Variable(index=[year, region], unit="\$/person")

    function run_timestep(p, v, d, t)

        for r in d.region
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

function calc_totaladaptationcosts(p, v, d, t, annual_year, r)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    v.act_adaptationcosts_total_ann[yr,r] = p.ac_adaptationcosts_economic_ann[yr,r] + p.ac_adaptationcosts_sealevelrise_ann[yr,r] + p.ac_adaptationcosts_noneconomic_ann[yr,r]
    v.act_percap_adaptationcosts_ann[yr,r] = v.act_adaptationcosts_total_ann[yr,r] / p.pop_population_region_ann[yr,r]
end

