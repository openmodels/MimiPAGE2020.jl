methane_on_crops = myloadcsv("data/Corp_yield/methane_crop_yield_value.csv")
@defcomp MarketDamageAQ begin
    country = Index()

    # Incoming parameter: Global CH4 emissions from ch4emissions component
    global_ch4_emissions = Parameter(index=[time], unit="Mtonne/year")

    # Impact parameters: value per Mt methane emitted in year 1, year 2, ..., year 50
    crop_yield_value_per_mton_ch4 = Parameter(index=[country, 50], unit="\$/Mtonne")

    # Component variable to store total crop yield value
    total_crop_yield_value = Variable(index=[time, country], unit="\$")

    function run_timestep(p, v, d, t)
        # Model Year
        y_year = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]
        y_year_0 = 2015  # Model Start Year

        for c in d.country
            total_value = 0.0
            for tt in 1:50
                if t > 1
                    # Determine the current year
                    uu = gettime(t) - tt + 1

                    if uu <= 2020
                        # Use historical data
                        if t - tt + 1 > 0 && t - tt + 1 <= length(p.global_ch4_emissions)
                            total_value += p.global_ch4_emissions[TimestepIndex(t - tt + 1)] * p.crop_yield_value_per_mton_ch4[c, tt]
                        end
                    else
                        # Linear interpolation
                        y1, y2 = find_model_years(uu, y_year)
                        e1 = p.global_ch4_emissions[TimestepIndex(findfirst(==(y1), y_year))]
                        e2 = p.global_ch4_emissions[TimestepIndex(findfirst(==(y2), y_year))]

                        # Linear interpolation formula
                        interpolated_emission = e1 + (e2 - e1) * (uu - y1) / (y2 - y1)
                        total_value += interpolated_emission * p.crop_yield_value_per_mton_ch4[c, tt]
                    end
                end
            end
            v.total_crop_yield_value[t, c] = total_value
        end
    end
end

# Function to find which model years the current year (uu) falls between
function find_model_years(uu, model_years)
    for i in 1:(length(model_years) - 1)
        if model_years[i] <= uu && uu <= model_years[i+1]
            return model_years[i], model_years[i+1]
        end
    end
    error("Year not found between model years.")
end

function addMarketDamageAQ(model::Model)
    marketdamageaqcomp = add_comp!(model, MarketDamageAQ)
    formatteddata = zeros(dim_count(model, :country), 50)
    for t in 1:50
        formatteddata[:, t] =readcountrydata_i_const(model, methane_on_crops, :ISO3, Symbol(t))
    end
    marketdamageaqcomp[:crop_yield_value_per_mton_ch4] = formatteddata
    return marketdamageaqcomp
end