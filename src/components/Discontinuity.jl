include("../utils/country_tools.jl")

@defcomp Discontinuity begin
    country = Index()

    model = Parameter{Model}()
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")

    rand_discontinuity = Parameter(unit="unitless", default=.5)

    irefeqdis_eqdiscimpact = Variable(index=[country], unit="%")
    wincf_weightsfactor_sea = Parameter(index=[region], unit="")
    wdis_gdplostdisc = Parameter(unit="%", default=3.)

    igdpeqdis_eqdiscimpact = Variable(index=[time,country], unit="%")
    rgdp_per_cap_NonMarketRemainGDP = Parameter(index=[time,country], unit="\$/person")
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=34298.93698672955)
    ipow_incomeexponent = Parameter(unit="unitless", default=-0.13333333333333333)

    igdp_realizeddiscimpact = Variable(index=[time,country], unit="%")
    occurdis_occurrencedummy = Variable(index=[time], unit="unitless")
    expfdis_discdecay = Variable(index=[time], unit="unitless")

    distau_discontinuityexponent = Parameter(unit="unitless", default=20.)

    idis_lossfromdisc = Variable(index=[time], unit="degreeC")
    tdis_tolerabilitydisc = Parameter(unit="degreeC", default=1.5)
    rt_g_globaltemperature = Parameter(index=[time], unit="degreeC")
    pdis_probability = Parameter(unit="%/degreeC", default=20.)

    isatg_saturationmodification = Parameter(unit="unitless")
    isat_satdiscimpact = Variable(index=[time,country], unit="%")

    isat_per_cap_DiscImpactperCapinclSaturation = Variable(index=[time,country], unit="\$/person")
    rcons_per_cap_DiscRemainConsumption = Variable(index=[time, country], unit="\$/person")
    rcons_per_cap_NonMarketRemainConsumption = Parameter(index=[time, country], unit="\$/person")

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

        wincf_weightsfactor_sea_country = regiontocountry(p.model, p.wincf_weightsfactor_sea)

        for cc in d.country
            v.irefeqdis_eqdiscimpact[cc] = wincf_weightsfactor_sea_country[cc] * p.wdis_gdplostdisc

            v.igdpeqdis_eqdiscimpact[t,cc] = v.irefeqdis_eqdiscimpact[cc] * ((p.rgdp_per_cap_NonMarketRemainGDP[t,cc] < 0 ? 0 : p.rgdp_per_cap_NonMarketRemainGDP[t,cc]) / p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_incomeexponent

            if is_first(t)
                v.igdp_realizeddiscimpact[t,cc] = v.occurdis_occurrencedummy[t] * (1 - v.expfdis_discdecay[t]) * v.igdpeqdis_eqdiscimpact[t,cc]
            else
                v.igdp_realizeddiscimpact[t,cc] = v.igdp_realizeddiscimpact[t - 1,cc] + v.occurdis_occurrencedummy[t] * (1 - v.expfdis_discdecay[t]) * (v.igdpeqdis_eqdiscimpact[t,cc] - v.igdp_realizeddiscimpact[t - 1,cc])
            end

            if v.igdp_realizeddiscimpact[t,cc] < p.isatg_saturationmodification
                v.isat_satdiscimpact[t,cc] = v.igdp_realizeddiscimpact[t,cc]
            else
                v.isat_satdiscimpact[t,cc] = p.isatg_saturationmodification + (100 - p.isatg_saturationmodification) * ((v.igdp_realizeddiscimpact[t,cc] - p.isatg_saturationmodification) / ((100 - p.isatg_saturationmodification) + (v.igdp_realizeddiscimpact[t,cc] - p.isatg_saturationmodification)))
            end
            v.isat_per_cap_DiscImpactperCapinclSaturation[t,cc] = (v.isat_satdiscimpact[t,cc] / 100) * p.rgdp_per_cap_NonMarketRemainGDP[t,cc]
            v.rcons_per_cap_DiscRemainConsumption[t,cc] = p.rcons_per_cap_NonMarketRemainConsumption[t,cc] - v.isat_per_cap_DiscImpactperCapinclSaturation[t,cc]
        end
    end
end

function adddiscontinuity(model::Model)
    discontinuity = add_comp!(model, Discontinuity)

    discontinuity[:model] = model

    discontinuity
end
