@defcomp AbatementCostsCO2 begin
    country = Index()

    ac_0_20_co2 = Parameter(index=[region], unit="\$/tonne") # decrease in CO2 at tax
    ac_0_20_gdp = Parameter(index=[region], unit="\$/tonne") # decrease in GDP at tax

    function run_timestep(p, v, d, t)
        # delta y = (y_goal - y_t) / tau = y_t+1 - y_t
        #   => y_t+1 = y_goal / tau + (1 - 1 / tau) y_t

        # Adjust so not over 1 and goes to 1 as p -> inf
        abated / (exp(-carbonprice / 500) + abated)
    end
end

function addabatementcostsco2(model::Model)
    abatementcostscomp = add_comp!(model, AbatementCostsCO2)

    macs = readcountrydata_im_ft(model, "data/macs.csv", "iso", "bs", nothing,
                                 (row, time) -> row["ac_0-20_co2"])

    return abatementcostscomp
end
