methane_on_crops = myloadcsv("data/Corp_yield/methane_crop_yield_value.csv")
historical_emissions = myloadcsv("data/Corp_yield/Historical_methane emissions.csv")

function find_model_years(uu, model_years)
    for i in 1:(length(model_years) - 1)
        if model_years[i] <= uu && uu <= model_years[i+1]
            return i, i+1 
        end
    end
    error("Year not found between model years.")
end

function addMarketDamageAQ(model::Model)
    marketdamageaqcomp = add_comp!(model, MarketDamageAQ)
    formatteddata = zeros(dim_count(model, :country), 50)
    for t in 1:50
        formatteddata[:, t] = readcountrydata_i_const(model, methane_on_crops, :ISO3, Symbol(t))
    end

    # The year can be passed through model parameters
    marketdamageaqcomp[:y_year_0] = 2015.
    marketdamageaqcomp[:y_year] = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]

    marketdamageaqcomp[:crop_yield_value_per_mton_ch4] = formatteddata
    return marketdamageaqcomp
end

@defcomp MarketDamageAQ begin
    country = Index()

    # Incoming parameter: Global CH4 emissions from ch4emissions component
    global_ch4_emissions = Parameter(index=[time], unit="Mtonne/year")

    # Impact parameters: value per Mt methane emitted in year 1, year 2, ..., year 50
    crop_yield_value_per_mton_ch4 = Parameter(index=[country, 50], unit="\$/Mtonne")

    # Component variable to store total crop yield value
    total_crop_yield_value = Variable(index=[time, country], unit="\$")

    # Define the y_year-0 parameter
    y_year_0 = Parameter(unit="year")

    # Define the y_year parameter (for interpolation)
    y_year = Parameter(index=[10], unit="year")  # 10 time points

    # Regional-Level Methane Emissions
    e_regionalCH4emissions = Variable(index=[time, region], unit="Mtonne/year")

    # Global Methane Emissions
    e_globalCH4emissions = Variable(index=[time], unit="Mtonne/year")
    
    function run_timestep(p, v, d, t)
        # Aggregating Regional Emissions at Each Time Step to Determine Global Methane Emissions
        v.e_globalCH4emissions[t] = sum(v.e_regionalCH4emissions[t, :])
    end
end

    function run_timestep(p, v, d, t)
        for c in d.country
            for tt in 1:50
                uu = gettime(t) - tt + 1  # Current Year
                
                # Using Historical Data
                if uu >= 1970 && uu <= 2019
                    v.total_crop_yield_value[t, c] += historical_emissions[!, string(uu)] * p.crop_yield_value_per_mton_ch4[c, tt]
                elseif uu >= 2020 && uu <= 2300
                    if uu in p.y_year
                        idx = findfirst(x -> x == uu, p.y_year)
                        e = p.global_ch4_emissions[TimestepIndex(idx)]
                        v.total_crop_yield_value[t, c] += e * p.crop_yield_value_per_mton_ch4[c, tt]
                    else
                        i1, i2 = find_model_years(uu, p.y_year)
                        y1, y2 = p.y_year[i1], p.y_year[i2]
                        e1 = p.global_ch4_emissions[TimestepIndex(i1)]
                        e2 = p.global_ch4_emissions[TimestepIndex(i2)]
                        interpolated_emission = e1 + (e2 - e1) * (uu - y1) / (y2 - y1)
                        v.total_crop_yield_value[t, c] += interpolated_emission * p.crop_yield_value_per_mton_ch4[c, tt]
                    end
                end
            end
        end
    end
    