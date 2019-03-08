using Mimi

@defcomp ClimateTemperature begin
    region = Index()

    # Basic parameters
    area = Parameter(index=[region], unit="km2")
    y_year_0 = Parameter(unit="year")
    y_year = Parameter(index=[time], unit="year")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)

    # Initial temperature outputs
    rt_g0_baseglobaltemp = Parameter(unit="degreeC", default=0.9461666666666667) #needed for feedback in CO2 cycle component
    rtl_0_baselandtemp = Variable(index=[region], unit="degreeC")
    rtl_g0_baselandtemp = Variable(unit="degreeC") #needed for feedback in CH4 and N2O cycles

    # Total anthropogenic forcing
    ft_totalforcing = Parameter(index=[time], unit="W/m2")
    fs_sulfateforcing = Parameter(index=[time, region], unit="W/m2")

    fant_anthroforcing = Variable(index=[time], unit="W/m2")

    # Rate of change of forcing
    ft_0_totalforcing0 = Parameter(unit="W/m2", default=3.202)
    fsd_g_0_directsulphate0 = Parameter(unit="W/m2", default=-0.46666666666666673)
    fsi_g_0_indirectsulphate0 = Parameter(unit="W/m2", default=-0.17529148701061475)

    # Climate sensitivity calculations
    tcr_transientresponse = Parameter(unit="degreeC", default=1.7666666666666668)
    frt_warminghalflife = Parameter(unit="year", default=28.333333333333332)

    ecs_climatesensitivity = Variable(unit="degreeC")

    # Unadjusted temperature calculations
    fslope_CO2forcingslope = Parameter(unit="W/m2", default=5.5)
    pt_g_preliminarygmst = Variable(index=[time], unit="degreeC")

    # Global outputs
    rt_g_globaltemperature = Variable(index=[time], unit="degreeC")
    rto_g_oceantemperature = Variable(index=[time], unit="degreeC")
    rtl_g_landtemperature = Variable(index=[time], unit="degreeC")

    # Regional outputs
    ampf_amplification = Parameter(index=[region])

    rtl_realizedtemperature = Variable(index=[time, region], unit="degreeC")

    function init(p, v, d)
        println(0)
        for rr in d.region
            v.rtl_0_baselandtemp[rr] = p.rt_g0_baseglobaltemp * p.ampf_amplification[rr]
        end

        # Equation 21 from Hope (2006): initial global land temperature
        v.rtl_g0_baselandtemp = sum(v.rtl_0_baselandtemp .* p.area) / sum(p.area)

        # Inclusion of transient climate response from Hope (2009)
        v.ecs_climatesensitivity = p.tcr_transientresponse / (1. - (p.frt_warminghalflife / 70.) * (1. - exp(-70. / p.frt_warminghalflife)))
    end

    function run_timestep(p, v, d, tt)
        # Grand total forcing
        v.fant_anthroforcing[tt] = p.ft_totalforcing[tt] + sum(p.area .* p.fs_sulfateforcing[tt, :]) / p.area_e_eartharea

        # Rate of change of grand total forcing
        if is_first(tt)
            rate_fant = 0 # inferred from spreadsheet
            deltat = p.y_year[tt] - p.y_year_0
        elseif is_timestep(tt, 2)
            fant0 = p.ft_0_totalforcing0 + p.fsd_g_0_directsulphate0 + p.fsi_g_0_indirectsulphate0
            rate_fant = (v.fant_anthroforcing[tt-1] - fant0) / (p.y_year[tt-1] - p.y_year_0)
            deltat = p.y_year[tt] - p.y_year[tt-1]
        else
            rate_fant = (v.fant_anthroforcing[tt-1] - v.fant_anthroforcing[tt-2]) / (p.y_year[tt-1] - p.y_year[tt-2])
            deltat = p.y_year[tt] - p.y_year[tt-1]
        end

        BB = v.ecs_climatesensitivity / (p.fslope_CO2forcingslope * log(2.0)) * rate_fant
        EXPT = exp(-deltat / p.frt_warminghalflife)

        if is_first(tt)
            fant0 = p.ft_0_totalforcing0 + p.fsd_g_0_directsulphate0 + p.fsi_g_0_indirectsulphate0
            AA = v.ecs_climatesensitivity / (p.fslope_CO2forcingslope * log(2.0)) * fant0
            v.pt_g_preliminarygmst[tt] = p.rt_g0_baseglobaltemp + (AA - p.rt_g0_baseglobaltemp) * (1 - EXPT) # Drop BB because 0
        else
            AA = v.ecs_climatesensitivity / (p.fslope_CO2forcingslope * log(2.0)) * v.fant_anthroforcing[tt-1]
            v.pt_g_preliminarygmst[tt] = v.pt_g_preliminarygmst[tt-1] + (AA - p.frt_warminghalflife*BB - v.pt_g_preliminarygmst[tt-1]) * (1 - EXPT) + deltat * BB
        end

        # Without surface albedo, just equal
        v.rt_g_globaltemperature[tt] = v.pt_g_preliminarygmst[tt]

        # Adding adjustment, from Hope (2009)
        for rr in d.region
            v.rtl_realizedtemperature[tt, rr] = v.rt_g_globaltemperature[tt] * p.ampf_amplification[rr]
        end

        # Land average temperature
        v.rtl_g_landtemperature[tt] = sum(v.rtl_realizedtemperature[tt, :]' .* p.area') / sum(p.area)

        # Ocean average temperature
        v.rto_g_oceantemperature[tt] = (p.area_e_eartharea * v.rt_g_globaltemperature[tt] - sum(p.area) * v.rtl_g_landtemperature[tt]) / (p.area_e_eartharea - sum(p.area))
    end
end
