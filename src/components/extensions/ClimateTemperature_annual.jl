function calc_temp(p, v, d, tt, annual_year)
    # for every year, do the same calculations, but then with the new annual_year variables
    yr = annual_year - 2015 + 1 # + 1 because of 1-based indexing in Julia

    # linear interpolation between the years of analysis, forward-stepping, up to gettime(tt)
    ## interpolation here is also linear for 2015-2020
    if is_first(tt)
        frac = annual_year - 2015
        fraction_timestep = frac / ((gettime(tt)) - 2015)

        v.pt_g_preliminarygmst_ann[yr] = (p.pt_g_preliminarygmst[tt]) * (fraction_timestep) + p.rt_g0_baseglobaltemp * (1 - fraction_timestep)  # difference_to_next_tt * ratio_to_there
    else
        frac = annual_year - gettime(tt - 1)
        fraction_timestep = frac / ((gettime(tt)) - (gettime(tt - 1))) # check if +1 might also need to feature here.

        v.pt_g_preliminarygmst_ann[yr] = (p.pt_g_preliminarygmst[tt] ) * (fraction_timestep) + p.pt_g_preliminarygmst[tt - 1] * (1 - fraction_timestep) # difference_to_next_tt * ratio_to_there
    end
    # Without surface albedo, just equal
    v.rt_g_globaltemperature_ann[yr] = v.pt_g_preliminarygmst_ann[yr]


    # Setting regional temperature
    for r in d.region
        if use_variability
            r_variationtemp = rand(Normal(0.0, max(0., p.rvarsd_regionalvariabilitystandarddeviation[r]))) # NEW - with variation
        else
            r_variationtemp = 0 # NEW - no variation
        end
        v.rtl_realizedtemperature_ann[yr, r] = v.rt_g_globaltemperature_ann[yr] * p.ampf_amplification[r] + r_variationtemp # NEW - add interannual variability
    end


    # Setting global temperature
    if use_variability
        g_variationtemp = rand(Normal(0.0, max(0., p.gvarsd_globalvariabilitystandarddeviation)))
    else
        g_variationtemp = 0
    end
    v.rt_g_globaltemperature_ann[yr] = v.pt_g_preliminarygmst_ann[yr] + g_variationtemp

    # Land average temperature
    v.rtl_g_landtemperature_ann[yr] = sum(v.rtl_realizedtemperature_ann[yr, :]' .* p.area') / sum(p.area)

    # Ocean average temperature
    v.rto_g_oceantemperature_ann[yr] = (p.area_e_eartharea * v.rt_g_globaltemperature_ann[yr] - sum(p.area) * v.rtl_g_landtemperature_ann[yr]) / (p.area_e_eartharea - sum(p.area))

end


@defcomp ClimateTemperature begin

    region = Index()
    year = Index()

    # Basic parameters
    area = Parameter(index=[region], unit="km2")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)
    ampf_amplification = Parameter(index=[region])

    # Initial temperature outputs
    rt_g0_baseglobaltemp = Parameter(unit="degreeC", default=0.9461666666666667) # needed for feedback in CO2 cycle component

    # variability parameters
    gvarsd_globalvariabilitystandarddeviation = Parameter(unit="degreeC", default=0.11294)  # default from https://github.com/jkikstra/climvar
    rvarsd_regionalvariabilitystandarddeviation = Parameter(index=[region], unit="degreeC") # provided in data folder

    # Unadjusted temperature calculations
    pt_g_preliminarygmst = Parameter(index=[time], unit="degreeC")
    pt_g_preliminarygmst_ann = Variable(index=[year], unit="degreeC")

    # Global outputs
    rt_g_globaltemperature_ann = Variable(index=[year], unit="degreeC")
    rto_g_oceantemperature_ann = Variable(index=[year], unit="degreeC")
    rtl_g_landtemperature_ann = Variable(index=[year], unit="degreeC")

    # Regional outputs
    rtl_realizedtemperature_ann = Variable(index=[year, region], unit="degreeC")

    function run_timestep(p, v, d, tt)
        # annual interpolation of the timestep-calculated variables.
        if is_first(tt)
            for annual_year = 2015:gettime(tt) # because p["y_year_0"] does not exist (globally)
                calc_temp(p, v, d, tt, annual_year) # NEW -- introduce function for calulating temperature
            end
        else
            for annual_year = (gettime(tt - 1) + 1):gettime(tt)
                calc_temp(p, v, d, tt, annual_year) # NEW -- use  function for calulating temperature
            end
        end
    end
end
