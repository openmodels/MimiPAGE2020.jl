@defcomp Discontinuity_annual begin

    region = Index()
    year = Index()

    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")
    yagg_periodspan = Parameter(index=[time], unit="year") # for doing in-component aggregation

    rand_discontinuity = Parameter(unit="unitless", default=.5)

    irefeqdis_eqdiscimpact = Parameter(index=[region], unit="%")

    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)
    ipow_incomeexponent = Parameter(unit="unitless", default=-0.13333333333333333)

    occurdis_occurrencedummy = Parameter(index=[time], unit="unitless")
    occurdis_occurrencedummy_sum = Variable(unit="unitless") # for analysis
    occurdis_occurrencedummy_ann = Variable(index=[year], unit="unitless")
    occurdis_occurrencedummy_ann_sum = Variable(unit="unitless") # for analysis

    distau_discontinuityexponent = Parameter(unit="unitless", default=20.)

    tdis_tolerabilitydisc = Parameter(unit="degreeC", default=1.5)
    pdis_probability = Parameter(unit="%/degreeC", default=20.)

    isatg_saturationmodification = Parameter(unit="unitless")

    isat_per_cap_DiscImpactperCapinclSaturation = Parameter(index=[time,region], unit="\$/person")
    isat_per_cap_DiscImpactperCapinclSaturation_sum = Variable(unit="\$/person") # for analysis
    isat_per_cap_DiscImpactperCapinclSaturation_ann = Variable(index=[year,region], unit="\$/person")
    isat_per_cap_DiscImpactperCapinclSaturation_ann_sum = Variable(unit="\$/person") # for analysis
    rcons_per_cap_DiscRemainConsumption = Parameter(index=[time, region], unit="\$/person")
    rcons_per_cap_DiscRemainConsumption_sum =  Variable(unit="\$/person") # for analysis
    rcons_per_cap_DiscRemainConsumption_ann = Variable(index=[year, region], unit="\$/person")
    rcons_per_cap_DiscRemainConsumption_ann_sum = Variable(unit="\$/person") # for analysis
    rcons_per_cap_NonMarketRemainConsumption_ann = Parameter(index=[year, region], unit="\$/person")


    function run_timestep(p, v, d, t)
        for r in d.region
            # calculate  for this specific year
            if is_first(t)
                # v.rcons_per_cap_DiscRemainConsumption_ann_sum = 0
                for annual_year = 2015:(gettime(t))
                    calc_discontinuity(p, v, d, t, annual_year, r)
                end
                if isequal(r, 8)
                    v.occurdis_occurrencedummy_sum = p.occurdis_occurrencedummy[t] * p.yagg_periodspan[t]
                    v.rcons_per_cap_DiscRemainConsumption_sum = sum(p.rcons_per_cap_DiscRemainConsumption[t,:]) * p.yagg_periodspan[t]
                    v.isat_per_cap_DiscImpactperCapinclSaturation_sum = sum(p.isat_per_cap_DiscImpactperCapinclSaturation[t,:]) * p.yagg_periodspan[t]
                end
            else
                for annual_year = (gettime(t - 1) + 1):(gettime(t))
                    calc_discontinuity(p, v, d, t, annual_year, r)


                    if isequal(annual_year, 2300)
                        if isequal(r, 8)
                            v.occurdis_occurrencedummy_ann_sum = sum(v.occurdis_occurrencedummy_ann[:])
                            v.rcons_per_cap_DiscRemainConsumption_ann_sum =  sum(v.rcons_per_cap_DiscRemainConsumption_ann[:,:])
                            v.isat_per_cap_DiscImpactperCapinclSaturation_ann_sum = sum(v.isat_per_cap_DiscImpactperCapinclSaturation_ann[:,:])
                        end
                    end
                end
                if isequal(r, 8)
                    # for analysis
                    v.occurdis_occurrencedummy_sum = v.occurdis_occurrencedummy_sum + p.occurdis_occurrencedummy[t] * p.yagg_periodspan[t]
                    v.rcons_per_cap_DiscRemainConsumption_sum = v.rcons_per_cap_DiscRemainConsumption_sum + sum(p.rcons_per_cap_DiscRemainConsumption[t,:]) * p.yagg_periodspan[t]
                    v.isat_per_cap_DiscImpactperCapinclSaturation_sum = v.isat_per_cap_DiscImpactperCapinclSaturation_sum + sum(p.isat_per_cap_DiscImpactperCapinclSaturation[t,:]) * p.yagg_periodspan[t]
                end

            end

        end
    end
end

function calc_discontinuity(p, v, d, t, annual_year, r)
    # setting the year for entry in lists.
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    # global variables only have to be done once. [r goes from 1 to 8]
    if isequal(r, 1)

        v.idis_lossfromdisc_ann[yr] = max(0, p.rt_g_globaltemperature_ann[yr] - p.tdis_tolerabilitydisc) # global temperature minus 1.5 (default)

        if is_first(t)
            if v.idis_lossfromdisc_ann[yr] * (p.pdis_probability / 100) > p.rand_discontinuity # (temp - 1.5)*0.2 >? .5 (default)
                v.occurdis_occurrencedummy_ann[yr] = 1
            else
                v.occurdis_occurrencedummy_ann[yr] = 0
            end
            v.expfdis_discdecay_ann[yr] = exp(-(p.y_year[t] - p.y_year_0) / p.distau_discontinuityexponent) # left same as timestep version
        else
            if v.idis_lossfromdisc_ann[yr] * (p.pdis_probability / 100) > p.rand_discontinuity
                v.occurdis_occurrencedummy_ann[yr] = 1
            elseif v.occurdis_occurrencedummy_ann[yr - 1] == 1
                v.occurdis_occurrencedummy_ann[yr] = 1
            else
                v.occurdis_occurrencedummy_ann[yr] = 0
            end
            v.expfdis_discdecay_ann[yr] = exp(-(p.y_year[t] - p.y_year[t - 1]) / p.distau_discontinuityexponent) # left same as timestep version
        end
    end

    # in growth effects with feedback, `p.rgdp_per_cap_NonMarketRemainGDP_ann[yr,r]` goes below zero, leading to issues here.
    v.igdpeqdis_eqdiscimpact_ann[yr,r] = p.irefeqdis_eqdiscimpact[r] * (p.rgdp_per_cap_NonMarketRemainGDP_ann[yr,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_incomeexponent

    if is_first(t)
        v.igdp_realizeddiscimpact_ann[yr,r] = v.occurdis_occurrencedummy_ann[yr] * (1 - v.expfdis_discdecay_ann[yr]) * v.igdpeqdis_eqdiscimpact_ann[yr,r]
    else
        v.igdp_realizeddiscimpact_ann[yr,r] = v.igdp_realizeddiscimpact_ann[yr - 1,r] + v.occurdis_occurrencedummy_ann[yr] * (1 - v.expfdis_discdecay_ann[yr]) * (v.igdpeqdis_eqdiscimpact_ann[yr,r] - v.igdp_realizeddiscimpact_ann[yr - 1,r])
    end

    if v.igdp_realizeddiscimpact_ann[yr,r] < p.isatg_saturationmodification    #### analyse this in dissertation?
        v.isat_satdiscimpact_ann[yr,r] = v.igdp_realizeddiscimpact_ann[yr,r]
    else
        v.isat_satdiscimpact_ann[yr,r] = p.isatg_saturationmodification + (100 - p.isatg_saturationmodification) * ((v.igdp_realizeddiscimpact_ann[yr,r] - p.isatg_saturationmodification) / ((100 - p.isatg_saturationmodification) + (v.igdp_realizeddiscimpact_ann[yr,r] - p.isatg_saturationmodification)))
    end

    v.isat_per_cap_DiscImpactperCapinclSaturation_ann[yr,r] = (v.isat_satdiscimpact_ann[yr,r] / 100) * p.rgdp_per_cap_NonMarketRemainGDP_ann[yr,r]
    v.rcons_per_cap_DiscRemainConsumption_ann[yr,r] = p.rcons_per_cap_NonMarketRemainConsumption_ann[yr,r] - v.isat_per_cap_DiscImpactperCapinclSaturation_ann[yr,r]
    if v.rcons_per_cap_DiscRemainConsumption_ann[yr,r] < 0
        v.rcons_per_cap_DiscRemainConsumption_ann[yr,r] = 0.
    end
end


