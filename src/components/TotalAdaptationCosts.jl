
using Mimi

@defcomp TotalAdaptationCosts begin
    region = Index()
    y_year = Parameter(index=[time], unit="year")

    #Mortality adaptation costs parameters
    fothernonmarketc = Parameter(unit = "unitless", default = 0.4)
    rt_g_globaltemperature = Parameter(index=[time], unit="degreeC")
    pop_population = Parameter(index=[time, region], unit="million person")
    VSL = Parameter(index=[region], unit="\$/")
    b0c = Parameter(index=[region])
    b1c = Parameter(index=[region])
    b2c = Parameter(index=[region])
    b3c = Parameter(index=[region])


    #Mortality adaptation costs variables
    deaths = Variable(index=[time,region], unit="million person")
    mort_adaptation_costs_damages = Variable(index=[time, region], unit = "deaths/person")
    mort_adaptation_costs = Variable(index=[time, region], unit = "\$/")
    mort_adaptationcosts_percap = Variable(index=[time, region], unit = "\$/person")


    #Total Adaptation Costs
    pop_population = Parameter(index=[time, region], unit= "million person")
    ac_adaptationcosts_economic = Parameter(index=[time, region], unit="\$million")
    ac_adaptationcosts_noneconomic = Parameter(index=[time, region], unit="\$million")
    ac_adaptationcosts_sealevelrise = Parameter(index=[time, region], unit="\$million")

    non_economic_adaptation_costs=Variable(index=[time, region], unit="\$")
    act_adaptationcosts_total = Variable(index=[time, region], unit="\$million")
    act_percap_adaptationcosts = Variable(index=[time, region], unit="\$/person")

    function run_timestep(p, v, d, t)

        for r in d.region

             # Mortality adaptation costs

     v.mort_adaptation_costs_damages[t,r] =  (p.b0c[r])*p.rt_g_globaltemperature[t]+(p.b1c[r])*(p.rt_g_globaltemperature[t])^2+(p.b2c[r])*p.rt_g_globaltemperature[t]*p.y_year[t]+(p.b3c[r])*((p.rt_g_globaltemperature[t])^2)*p.y_year[t]


            v.deaths[t,r] = v.mort_adaptation_costs_damages[t,r]*p.pop_population[t,r]

            v.mort_adaptation_costs[t,r] = v.deaths[t,r]*p.VSL[r]

            v.mort_adaptationcosts_percap[t,r] = v.mort_adaptation_costs[t,r]/(p.pop_population[t,r])

            v.non_economic_adaptation_costs[t,r]=v.mort_adaptation_costs[t,r]+p.ac_adaptationcosts_noneconomic[t,r]*p.fothernonmarketc

            v.act_adaptationcosts_total[t,r] = p.ac_adaptationcosts_economic[t,r] + p.ac_adaptationcosts_sealevelrise[t,r]+ v.non_economic_adaptation_costs[t,r]
            v.act_percap_adaptationcosts[t,r] = v.act_adaptationcosts_total[t,r]/p.pop_population[t,r]
        end
    end
end
