@defcomp MarketDamagesRegionBayes begin
    region = Index()
    y_year = Parameter(index=[time], unit="year")

    #incoming parameters from Climate
    rtl_realizedtemperature = Parameter(index=[time, region], unit="degreeC")

    #tolerability and impact variables from PAGE damages that Burke damages also require
    rcons_per_cap_SLRRemainConsumption = Parameter(index=[time, region], unit = "\$/person")
    rgdp_per_cap_SLRRemainGDP = Parameter(index=[time, region], unit = "\$/person")
    save_savingsrate = Parameter(unit= "%", default=15.)
    wincf_weightsfactor_market =Parameter(index=[region], unit="")
    ipow_MarketIncomeFxnExponent =Parameter(default=0.0)
    GDP_per_cap_focus_0_FocusRegionEU = Parameter(default=34298.93698672955)

    # added impact parameters and variables specifically for Burke damage function
    rtl_abs_0_realizedabstemperature = Parameter(index = [region]) # 1979-2005 means, Yumashev et al. 2019 Supplementary Table 16, table in /data directory
    rtl_0_realizedtemperature = Parameter(index = [region]) # temperature change between PAGE base year temperature and rtl_abs_0 (?)
    impf_coefflinearregion_bayes = Parameter(index = [region], unit = "none") # regional damage functions based on temperature and growth projections
    impf_coeffquadrregion_bayes = Parameter(index = [region], unit = "none")
    impf_coeffcubicregion_bayes = Parameter(index = [region], unit = "none")
    tcal_burke = Parameter(default = 21.) # calibration temperature for the impact function
    nlag_burke = Parameter(default = 1.) # Yumashev et al. (2019) allow for one or two lags

    i_burke_regionalimpact = Variable(index = [time, region], unit = "degreeC") # Burke-specific warming impact, unlike PAGE-specific impact in absolute temperatures
    i1log_impactlogchange = Variable(index = [time, region]) # intermediate variable for computation

    #impact variables from PAGE damages that Burke damages also require
    isatg_impactfxnsaturation = Parameter(unit="unitless")
    rcons_per_cap_MarketRemainConsumption = Variable(index=[time, region], unit = "\$/person")
    rgdp_per_cap_MarketRemainGDP = Variable(index=[time, region], unit = "\$/person")
    iref_ImpactatReferenceGDPperCap=Variable(index=[time, region])
    igdp_ImpactatActualGDPperCap=Variable(index=[time, region])

    isat_ImpactinclSaturationandAdaptation= Variable(index=[time,region], unit = "%GDP")
    isat_per_cap_ImpactperCapinclSaturationandAdaptation = Variable(index=[time,region])

    # add parameter to switch off this component
    switchoff_marketdamages = Parameter(default = 0.)

    # add parameter to include error variance for uncertainty
    errvarbayes_errorvariancebayes = Parameter(index = [region])
    inclerr_includerrorvariance = Parameter(default = 0.)
    impfseed_montecarloseedcoeffs = Parameter(default = 1.) # to implement multivariate Normal

    function run_timestep(p, v, d, t)

        if is_first(t) && p.inclerr_includerrorvariance != 0.
            # draw the parameters for a fixed seed from multivariate Gaussian if inclerr is not zero, i.e. in Monte Carlo
                ### EU = 1
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[1] = rand(MvNormal([0.016778919178202237, -6.589588822829189e-4],
                                                      [8.37310821714339E-08  -3.23802901733813E-09;
                                                      -3.23802901733813E-09 1.25609945404031E-10]))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[1] = rand(MvNormal([0.016778919178202237, -6.589588822829189e-4],
                                                      [8.37310821714339E-08  -3.23802901733813E-09;
                                                      -3.23802901733813E-09 1.25609945404031E-10]))[2]


                ### US = 2
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[2] = rand(MvNormal([0.013454251728767158, -4.930689164122343e-4],
                                                      [1.40031875371829E-07 -4.33794288121924E-09;
                                                      -4.33794288121924E-09  1.34599902884995E-10]))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[2] = rand(MvNormal([0.013454251728767158, -4.930689164122343e-4],
                                                      [1.40031875371829E-07 -4.33794288121924E-09;
                                                      -4.33794288121924E-09  1.34599902884995E-10]))[2]


                ### OECD = 3
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[3] = rand(MvNormal([0.016494824209702184, -6.018588172029741e-4],
                                                      [2.63399855738746E-07  -9.09251649796261E-09;
                                                     -9.09251649796261E-09 3.14400766353161E-10]))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[3] = rand(MvNormal([0.016494824209702184, -6.018588172029741e-4],
                                                      [2.63399855738746E-07  -9.09251649796261E-09;
                                                     -9.09251649796261E-09 3.14400766353161E-10]))[2]

                ### USSR = 4
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[4] = rand(MvNormal([0.01658623965486268, -6.503382557688012e-4],
                                                        [1.81144828826549E-07  -8.74094674296174E-09;
                                                        -8.74094674296174E-09 4.25328114262381E-10]
                                                      ))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[4] = rand(MvNormal([0.01658623965486268, -6.503382557688012e-4],
                                                        [1.81144828826549E-07  -8.74094674296174E-09;
                                                        -8.74094674296174E-09 4.25328114262381E-10]))[2]

                ### China = 5
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[5] = rand(MvNormal([0.014147304068527754, -4.8029953805059963e-4],
                                                                [2.39627091985249E-07  -6.3945390287455E-09;
                                                                -6.3945390287455E-09 1.7094331161796E-10]
                                                                ))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[5] = rand(MvNormal([0.014147304068527754, -4.8029953805059963e-4],
                                                                [2.39627091985249E-07  -6.3945390287455E-09;
                                                                -6.3945390287455E-09 1.7094331161796E-10]
                                                                ))[2]

                ### SEAsia = 6
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[6] = rand(MvNormal([0.019680709697788883, -6.235809776305397e-4],
                                                      [0.000000305809  -0.0000000001229;
                                                      -0.0000000001229 0.00000000042025]))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[6] = rand(MvNormal([0.019680709697788883, -6.235809776305397e-4],
                                                      [0.000000305809  -0.0000000001229;
                                                      -0.0000000001229 0.00000000042025]))[2]

                ### Africa = 7
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[7] = rand(MvNormal([0.01695479320678946, -5.449994771735894e-4],
                                                      [0.00000001968409  -9.65785578713003E-11;
                                                      -9.65785578713003E-11 0.0000000000300304]))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[7] = rand(MvNormal([0.01695479320678946, -5.449994771735894e-4],
                                                      [0.00000001968409  -9.65785578713003E-11;
                                                      -9.65785578713003E-11 0.0000000000300304]))[2]

                ### LatAmerica = 8
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coefflinearregion_bayes[8] = rand(MvNormal([0.01743093912793151, -5.945701704729174e-4],
                                                      [0.00000001423249  -3.08513859072823E-10;
                                                      -3.08513859072823E-10 0.00000000002601]))[1]
                Random.seed!(trunc(Int, p.impfseed_montecarloseedcoeffs))
                p.impf_coeffquadrregion_bayes[8] = rand(MvNormal([0.01743093912793151, -5.945701704729174e-4],
                                                      [0.00000001423249  -3.08513859072823E-10;
                                                      -3.08513859072823E-10 0.00000000002601]))[2]

        end

        for r in d.region



            # fix the current bug which implements the regional weights from SLR and discontinuity also for market and non-market damages (where weights should be uniformly one)
            p.wincf_weightsfactor_market[r] = 1.

            # calculate the regional temperature impact relative to baseline year and add it to baseline absolute value
            v.i_burke_regionalimpact[t,r] = (p.rtl_realizedtemperature[t,r] - p.rtl_0_realizedtemperature[r]) + p.rtl_abs_0_realizedabstemperature[r]

            # calculate the log change, depending on the number of lags specified
            v.i1log_impactlogchange[t,r] = p.nlag_burke * (p.impf_coefflinearregion_bayes[r]  * (v.i_burke_regionalimpact[t,r] - p.rtl_abs_0_realizedabstemperature[r]) +
                                p.impf_coeffquadrregion_bayes[r] * (v.i_burke_regionalimpact[t,r]^2 - p.rtl_abs_0_realizedabstemperature[r]^2) +
                                p.impf_coeffcubicregion_bayes[r] * (v.i_burke_regionalimpact[t,r]^3 - p.rtl_abs_0_realizedabstemperature[r]^3) +
                                p.inclerr_includerrorvariance * (rand(Normal(0, p.errvarbayes_errorvariancebayes[r]^0.5), 1)[1] -
                                                                 rand(Normal(0, p.errvarbayes_errorvariancebayes[r]^0.5), 1)[1]))

            # calculate the impact at focus region GDP p.c.
            v.iref_ImpactatReferenceGDPperCap[t,r] = 100 * p.wincf_weightsfactor_market[r] * (1 - exp(v.i1log_impactlogchange[t,r]))

            # calculate impacts at actual GDP
            if p.rgdp_per_cap_SLRRemainGDP[t,r] != 1 /(1-p.save_savingsrate/100)
                v.igdp_ImpactatActualGDPperCap[t,r]= v.iref_ImpactatReferenceGDPperCap[t,r]*
                    (p.rgdp_per_cap_SLRRemainGDP[t,r]/p.GDP_per_cap_focus_0_FocusRegionEU)^p.ipow_MarketIncomeFxnExponent
            else
                v.igdp_ImpactatActualGDPperCap[t,r] = 0.
            end

            # send impacts down a logistic path if saturation threshold is exceeded
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

            v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r] = (v.isat_ImpactinclSaturationandAdaptation[t,r]/100)*p.rgdp_per_cap_SLRRemainGDP[t,r]
            v.rcons_per_cap_MarketRemainConsumption[t,r] = p.rcons_per_cap_SLRRemainConsumption[t,r] - v.isat_per_cap_ImpactperCapinclSaturationandAdaptation[t,r]
            v.rgdp_per_cap_MarketRemainGDP[t,r] = v.rcons_per_cap_MarketRemainConsumption[t,r]/(1-p.save_savingsrate/100)


            if p.switchoff_marketdamages == 1.
                    v.rcons_per_cap_MarketRemainConsumption[t,r] = p.rcons_per_cap_SLRRemainConsumption[t,r]
                    v.rgdp_per_cap_MarketRemainGDP[t,r] = p.rgdp_per_cap_SLRRemainGDP[t,r]
            end

        end

    end
end

# Still need this function in order to set the parameters than depend on
# readpagedata, which takes model as an input. These cannot be set using
# the default keyword arg for now.

function addmarketdamagesregionbayes(model::Model)
    marketdamagesregionbayescomp = add_comp!(model, MarketDamagesRegionBayes)
    marketdamagesregionbayescomp[:rtl_abs_0_realizedabstemperature] = readpagedata(model, "data/rtl_abs_0_realizedabstemperature.csv")
    marketdamagesregionbayescomp[:rtl_0_realizedtemperature] = readpagedata(model, "data/rtl_0_realizedtemperature.csv")

    return marketdamagesregionbayescomp
end
