using Mimi

@defcomp NonMarketDamages begin
    region = Index()

    y_year = Parameter(index=[time], unit="year")

    #Mortality parameters
    rt_g_globaltemperature = Parameter(index=[time], unit="degreeC")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, region], unit = "\$/person")
    pop_population = Parameter(index=[time, region], unit="million person")
    VSL = Parameter(index=[region], unit="\$/")

    b0m = Parameter(index=[region])
    b1m = Parameter(index=[region])
    b2m = Parameter(index=[region])
    b3m = Parameter(index=[region])


    # Other non-market parameters

    rtl_realizedtemperature = Parameter(index=[time, region], unit="degreeC")
    impmax_maxtempriseforadaptpolicyNM = Parameter(index=[region], unit= "degreeC")
    atl_adjustedtolerableleveloftemprise = Parameter(index=[time,region], unit="degreeC")
    imp_actualreduction = Parameter(index=[time, region], unit= "%")
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    wincf_weightsfactor =Parameter(index=[region], unit="unitless")
    w_NonImpactsatCalibrationTemp =Parameter(unit="%GDP", default=0.5333333333333333)
    ipow_NonMarketIncomeFxnExponent =Parameter(unit="unitless", default=0.)
    iben_NonMarketInitialBenefit=Parameter(unit="%GDP/degreeC", default=0.08333333333333333)
    tcal_CalibrationTemp = Parameter(unit="degreeC", default=3.)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(unit="\$/person", default=27934.244777382406)
    pow_NonMarketExponent = Parameter(unit="", default=2.1666666666666665)


    # Mortality and other non-market parameters

    fothernonmarketd = Parameter(unit = "unitless", default = 0.4)
    rcons_per_cap_MarketRemainConsumption = Parameter(index=[time, region], unit = "\$/person")
    rgdp_per_cap_MarketRemainGDP = Parameter(index=[time, region], unit = "\$/person")
    save_savingsrate = Parameter(unit= "%", default=15.)

    #Mortality variables
    deaths = Variable(index=[time,region], unit="million person")
    mort_damages = Variable(index=[time, region], unit = "deaths/person")
    mort_impacts = Variable(index=[time, region], unit = "\$million")
    mort_impactspercap = Variable(index=[time, region], unit = "\$/person")

    #Other non-market variables
    i_regionalimpact = Variable(index=[time, region], unit="degreeC")
    iref_ImpactatReferenceGDPperCap=Variable(index=[time, region], unit="%")
    igdp_ImpactatActualGDPperCap=Variable(index=[time, region], unit="%")
    isat_ImpactinclSaturationandAdaptation= Variable(index=[time,region], unit="\$")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,region], unit="\$/person")
    other_non_market_impact= Variable(index=[time,region], unit="\$million")


    # Mortality and other non-market variables
    rcons_per_cap_NonMarketRemainConsumption = Variable(index=[time, region], unit = "\$/person")
    rgdp_per_cap_NonMarketRemainGDP = Variable(index=[time, region], unit = "\$/person")
    non_market_impact= Variable(index=[time,region], unit="\$")
    non_market_impact_per_cap=Variable(index=[time, region], unit = "\$/person")



    function run_timestep(p, v, d, t)

        for r in d.region

        # Mortality impacts

     v.mort_damages[t,r] = (p.b0m[r])*p.rt_g_globaltemperature[t]+(p.b1m[r])*(p.rt_g_globaltemperature[t])^2+(p.b2m[r])*p.rt_g_globaltemperature[t]*p.y_year[t]+(p.b3m[r])*((p.rt_g_globaltemperature[t])^2)*p.y_year[t]

            v.deaths[t,r] = v.mort_damages[t,r]*p.pop_population[t,r]

            v.mort_impacts[t,r] = v.deaths[t,r]*p.VSL[r]

            v.mort_impactspercap[t,r] = v.mort_impacts[t,r]/(p.pop_population[t,r])

        # Other non-market impacts

if p.rtl_realizedtemperature[t,r]-p.atl_adjustedtolerableleveloftemprise[t,r] < 0
                v.i_regionalimpact[t,r] = 0
            else
                v.i_regionalimpact[t,r] = p.rtl_realizedtemperature[t,r]-p.atl_adjustedtolerableleveloftemprise[t,r]
            end

            v.iref_ImpactatReferenceGDPperCap[t,r]= p.wincf_weightsfactor[r]*
                ((p.w_NonImpactsatCalibrationTemp + p.iben_NonMarketInitialBenefit *p.tcal_CalibrationTemp)*
                    (v.i_regionalimpact[t,r]/p.tcal_CalibrationTemp)^p.pow_NonMarketExponent - v.i_regionalimpact[t,r] * p.iben_NonMarketInitialBenefit)

            v.igdp_ImpactatActualGDPperCap[t,r]= v.iref_ImpactatReferenceGDPperCap[t,r]*
                (p.rgdp_per_cap_MarketRemainGDP[t,r]/p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_NonMarketIncomeFxnExponent

                if v.igdp_ImpactatActualGDPperCap[t,r] < p.isatg_impactfxnsaturation
                    v.isat_ImpactinclSaturationandAdaptation[t,r] = v.igdp_ImpactatActualGDPperCap[t,r]
                else
                    v.isat_ImpactinclSaturationandAdaptation[t,r] = p.isatg_impactfxnsaturation+
                        ((100-p.save_savingsrate)-p.isatg_impactfxnsaturation)*
                        ((v.igdp_ImpactatActualGDPperCap[t,r]-p.isatg_impactfxnsaturation)/
                        (((100-p.save_savingsrate)-p.isatg_impactfxnsaturation)+
                        (v.igdp_ImpactatActualGDPperCap[t,r]-
                        p.isatg_impactfxnsaturation)))
                    end

                if v.i_regionalimpact[t,r] < p.impmax_maxtempriseforadaptpolicyNM[r]
                    v.isat_ImpactinclSaturationandAdaptation[t,r]=v.isat_ImpactinclSaturationandAdaptation[t,r]*(1-p.imp_actualreduction[t,r]/100)
                else
                    v.isat_ImpactinclSaturationandAdaptation[t,r] = v.isat_ImpactinclSaturationandAdaptation[t,r] *
                        (1-(p.imp_actualreduction[t,r]/100)* p.impmax_maxtempriseforadaptpolicyNM[r] /
                        v.i_regionalimpact[t,r])
                end

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptation[t,r]/100)*p.rgdp_per_cap_MarketRemainGDP[t,r]
            v.other_non_market_impact[t,r]=p.fothernonmarketd*v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r]*(p.pop_population[t,r])

         # Total non-market impacts

            v.non_market_impact[t,r]=v.mort_impacts[t,r]+v.other_non_market_impact[t,r]

            v.non_market_impact_per_cap[t,r]=v.non_market_impact[t,r]/(p.pop_population[t,r])



            v.rcons_per_cap_NonMarketRemainConsumption[t,r] = p.rcons_per_cap_MarketRemainConsumption[t,r]-v.non_market_impact_per_cap[t,r]
            v.rgdp_per_cap_NonMarketRemainGDP[t,r] = v.rcons_per_cap_NonMarketRemainConsumption[t,r]/(1-p.save_savingsrate/100)




        end
    end
end


# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.
function addnonmarketdamages(model::Model)
    nonmarketdamagescomp = add_comp!(model, NonMarketDamages)
    nonmarketdamagescomp[:impmax_maxtempriseforadaptpolicyNM] = readpagedata(model, "data/impmax_noneconomic.csv")
    return nonmarketdamagescomp
end
