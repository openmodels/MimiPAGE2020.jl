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

    v.igdpeqdis_eqdiscimpact_ann[yr,r] = v.irefeqdis_eqdiscimpact[r] * (p.rgdp_per_cap_NonMarketRemainGDP_ann[yr,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_incomeexponent

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

end


@defcomp Discontinuity begin

    region = Index()
    year = Index()
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")
    y_year_ann = Parameter(index=[year], unit="year")
    yagg_periodspan = Parameter(index=[time], unit="year") # for doing in-component aggregation

    rand_discontinuity = Parameter(unit="unitless", default=.5)

    irefeqdis_eqdiscimpact = Variable(index=[region], unit="%")
    wincf_weightsfactor_sea = Parameter(index=[region], unit="")
    wdis_gdplostdisc = Parameter(unit="%", default=3.)

    igdpeqdis_eqdiscimpact = Variable(index=[time,region], unit="%")
    igdpeqdis_eqdiscimpact_ann = Variable(index=[year,region], unit="%")
    rgdp_per_cap_NonMarketRemainGDP = Parameter(index=[time,region], unit="\$/person")
    rgdp_per_cap_NonMarketRemainGDP_ann = Parameter(index=[year,region], unit="\$/person")
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)
    ipow_incomeexponent = Parameter(unit="unitless", default=-0.13333333333333333)

    igdp_realizeddiscimpact = Variable(index=[time,region], unit="%")
    igdp_realizeddiscimpact_ann = Variable(index=[year,region], unit="%")
    occurdis_occurrencedummy = Variable(index=[time], unit="unitless")
    occurdis_occurrencedummy_sum = Variable(unit="unitless") # for analysis
    occurdis_occurrencedummy_ann = Variable(index=[year], unit="unitless")
    occurdis_occurrencedummy_ann_sum = Variable(unit="unitless") # for analysis
    expfdis_discdecay = Variable(index=[time], unit="unitless")
    expfdis_discdecay_ann = Variable(index=[year], unit="unitless")


    distau_discontinuityexponent = Parameter(unit="unitless", default=20.)

    idis_lossfromdisc = Variable(index=[time], unit="degreeC")
    idis_lossfromdisc_ann = Variable(index=[year], unit="degreeC")
    tdis_tolerabilitydisc = Parameter(unit="degreeC", default=1.5)
    rt_g_globaltemperature = Parameter(index=[time], unit="degreeC")
    rt_g_globaltemperature_ann = Parameter(index=[year], unit="degreeC")
    pdis_probability = Parameter(unit="%/degreeC", default=20.)

    isatg_saturationmodification = Parameter(unit="unitless")
    isat_satdiscimpact = Variable(index=[time,region], unit="%")
    isat_satdiscimpact_ann = Variable(index=[year,region], unit="%")

    isat_per_cap_DiscImpactperCapinclSaturation = Variable(index=[time,region], unit="\$/person")
    isat_per_cap_DiscImpactperCapinclSaturation_sum = Variable(unit="\$/person") # for analysis
    isat_per_cap_DiscImpactperCapinclSaturation_ann = Variable(index=[year,region], unit="\$/person")
    isat_per_cap_DiscImpactperCapinclSaturation_ann_sum = Variable(unit="\$/person") # for analysis
    rcons_per_cap_DiscRemainConsumption = Variable(index=[time, region], unit="\$/person")
    rcons_per_cap_DiscRemainConsumption_sum =  Variable(unit="\$/person") # for analysis
    rcons_per_cap_DiscRemainConsumption_ann = Variable(index=[year, region], unit="\$/person")
    rcons_per_cap_DiscRemainConsumption_ann_sum = Variable(unit="\$/person") # for analysis
    rcons_per_cap_NonMarketRemainConsumption = Parameter(index=[time, region], unit="\$/person")
    rcons_per_cap_NonMarketRemainConsumption_ann = Parameter(index=[year, region], unit="\$/person")


    function run_timestep(p, v, d, t)

    v.idis_lossfromdisc[t] = max(0, p.rt_g_globaltemperature[t] - p.tdis_tolerabilitydisc)

    if is_first(t)
        if v.idis_lossfromdisc[t] * (p.pdis_probability / 100) > p.rand_discontinuity
            v.occurdis_occurrencedummy[t] = 1
        else
            v.occurdis_occurrencedummy[t] = 0
        end
        v.expfdis_discdecay[t] = exp(-(p.y_year[t] - p.y_year_0) / p.distau_discontinuityexponent)
    else
        if v.idis_lossfromdisc[t] * (p.pdis_probability / 100) > p.rand_discontinuity
            v.occurdis_occurrencedummy[t] = 1
        elseif v.occurdis_occurrencedummy[t - 1] == 1
                v.occurdis_occurrencedummy[t] = 1
            else
                v.occurdis_occurrencedummy[t] = 0
        end
        v.expfdis_discdecay[t] = exp(-(p.y_year[t] - p.y_year[t - 1]) / p.distau_discontinuityexponent)
    end

    for r in d.region
        v.irefeqdis_eqdiscimpact[r] = p.wincf_weightsfactor_sea[r] * p.wdis_gdplostdisc

        v.igdpeqdis_eqdiscimpact[t,r] = v.irefeqdis_eqdiscimpact[r] * (p.rgdp_per_cap_NonMarketRemainGDP[t,r] / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_incomeexponent

        if is_first(t)
            v.igdp_realizeddiscimpact[t,r] = v.occurdis_occurrencedummy[t] * (1 - v.expfdis_discdecay[t]) * v.igdpeqdis_eqdiscimpact[t,r]
        else
            v.igdp_realizeddiscimpact[t,r] = v.igdp_realizeddiscimpact[t - 1,r] + v.occurdis_occurrencedummy[t] * (1 - v.expfdis_discdecay[t]) * (v.igdpeqdis_eqdiscimpact[t,r] - v.igdp_realizeddiscimpact[t - 1,r])
        end

        if v.igdp_realizeddiscimpact[t,r] < p.isatg_saturationmodification
            v.isat_satdiscimpact[t,r] = v.igdp_realizeddiscimpact[t,r]
        else
            v.isat_satdiscimpact[t,r] = p.isatg_saturationmodification + (100 - p.isatg_saturationmodification) * ((v.igdp_realizeddiscimpact[t,r] - p.isatg_saturationmodification) / ((100 - p.isatg_saturationmodification) + (v.igdp_realizeddiscimpact[t,r] - p.isatg_saturationmodification)))
        end
        v.isat_per_cap_DiscImpactperCapinclSaturation[t,r] = (v.isat_satdiscimpact[t,r] / 100) * p.rgdp_per_cap_NonMarketRemainGDP[t,r]
        v.rcons_per_cap_DiscRemainConsumption[t,r] = p.rcons_per_cap_NonMarketRemainConsumption[t,r] - v.isat_per_cap_DiscImpactperCapinclSaturation[t,r]

            # calculate  for this specific year
        if is_first(t)
                # v.rcons_per_cap_DiscRemainConsumption_ann_sum = 0
            for annual_year = 2015:(gettime(t))
                calc_discontinuity(p, v, d, t, annual_year, r)
            end
            if isequal(r, 8)
                v.occurdis_occurrencedummy_sum = v.occurdis_occurrencedummy[t] * p.yagg_periodspan[t]
                v.rcons_per_cap_DiscRemainConsumption_sum = sum(v.rcons_per_cap_DiscRemainConsumption[t,:]) * p.yagg_periodspan[t]
                v.isat_per_cap_DiscImpactperCapinclSaturation_sum = sum(v.isat_per_cap_DiscImpactperCapinclSaturation[t,:]) * p.yagg_periodspan[t]
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
                v.occurdis_occurrencedummy_sum = v.occurdis_occurrencedummy_sum + v.occurdis_occurrencedummy[t] * p.yagg_periodspan[t]
                v.rcons_per_cap_DiscRemainConsumption_sum = v.rcons_per_cap_DiscRemainConsumption_sum + sum(v.rcons_per_cap_DiscRemainConsumption[t,:]) * p.yagg_periodspan[t]
                v.isat_per_cap_DiscImpactperCapinclSaturation_sum = v.isat_per_cap_DiscImpactperCapinclSaturation_sum + sum(v.isat_per_cap_DiscImpactperCapinclSaturation[t,:]) * p.yagg_periodspan[t]
            end

        end

    end
end
end
