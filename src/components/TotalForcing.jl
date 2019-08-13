

@defcomp TotalForcing begin
    f_CO2forcing = Parameter(index=[time], unit="W/m2")
    f_CH4forcing = Parameter(index=[time], unit="W/m2")
    f_N2Oforcing = Parameter(index=[time], unit="W/m2")
    f_lineargasforcing = Parameter(index=[time], unit="W/m2")
    exf_excessforcing = Parameter(index=[time], unit="W/m2")
    fs_sulfateforcing = Parameter(index=[time, region], unit="W/m2")

    area = Parameter(index=[region], unit="km2")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)

    # Total anthropogenic forcing
    ft_totalforcing = Variable(index=[time], unit="W/m2")
    fant_anthroforcing = Variable(index=[time], unit="W/m2")

    function run_timestep(p, v, d, tt)
        # From equation 16 of Hope (2006)
        v.ft_totalforcing[tt] = p.f_CO2forcing[tt] + p.f_CH4forcing[tt] + p.f_N2Oforcing[tt] + p.f_lineargasforcing[tt] + p.exf_excessforcing[tt]

        # Grand total forcing
        v.fant_anthroforcing[tt] = v.ft_totalforcing[tt] + sum(p.area .* p.fs_sulfateforcing[tt, :]) / p.area_e_eartharea
    end
end

