function calc_PermafrostTotal(p, v, d, t, annual_year)
    # Cumulative emissions CO2 perm
    v.perm_tot_ce_co2_ann[year] = 0.5 *(p.perm_sib_ce_co2_ann[year] + p.perm_jul_ce_co2_ann[year]) * (1 + p.perm_initial_c_stock_uncertainty/100)
    # Annual emissions CO2 perm
    v.perm_tot_e_co2_ann[year] = 0.5 *(p.perm_sib_e_co2_ann[year] + p.perm_jul_e_co2_ann[year]) * (1 + p.perm_initial_c_stock_uncertainty/100)
    # Cumulative emissions CH4 perm
    v.perm_tot_ce_ch4_ann[year] = 0.5 *(p.perm_sib_ce_ch4_ann[year] + p.perm_jul_ce_ch4_ann[year]) * (1 + p.perm_initial_c_stock_uncertainty/100)
end

@defcomp PermafrostTotal begin
    perm_sib_ce_co2 = Parameter(index=[time], unit="Mtonne CO2")
    perm_sib_ce_co2_ann = Parameter(index=[year], unit="Mtonne CO2")
    perm_jul_ce_co2 = Parameter(index=[time], unit="Mtonne CO2")
    perm_jul_ce_co2_ann = Parameter(index=[year], unit="Mtonne CO2")
    perm_sib_e_co2 = Parameter(index=[time], unit="MtonCO2/yr")
    perm_sib_e_co2_ann = Parameter(index=[year], unit="MtonCO2/yr")
    perm_jul_e_co2 = Parameter(index=[time], unit="MtonCO2/yr")
    perm_jul_e_co2_ann = Parameter(index=[year], unit="MtonCO2/yr")
    perm_sib_ce_ch4 = Parameter(index=[time], unit="Mtonne CH4")
    perm_sib_ce_ch4_ann = Parameter(index=[year], unit="Mtonne CH4")
    perm_jul_ce_ch4 = Parameter(index=[time], unit="Mtonne CH4")
    perm_jul_ce_ch4_ann = Parameter(index=[year], unit="Mtonne CH4")

    perm_initial_c_stock_uncertainty = Parameter(default=0.0)

    perm_tot_ce_co2 = Variable(index=[time], unit="Mtonne")
    perm_tot_ce_co2_ann = Variable(index=[year], unit="Mtonne")
    perm_tot_e_co2 = Variable(index=[time], unit="Mtonne")
    perm_tot_e_co2_ann = Variable(index=[year], unit="Mtonne")
    perm_tot_ce_ch4 = Variable(index=[time], unit="Mtonne")
    perm_tot_ce_ch4_ann = Variable(index=[year], unit="Mtonne")

    function run_timestep(p, v, d, tt)
        # Cumulative emissions CO2 perm
        v.perm_tot_ce_co2[tt] = 0.5 *(p.perm_sib_ce_co2[tt] + p.perm_jul_ce_co2[tt]) * (1 + p.perm_initial_c_stock_uncertainty/100)
        # Annual emissions CO2 perm
        v.perm_tot_e_co2[tt] = 0.5 *(p.perm_sib_e_co2[tt] + p.perm_jul_e_co2[tt]) * (1 + p.perm_initial_c_stock_uncertainty/100)
        # Cumulative emissions CH4 perm
        v.perm_tot_ce_ch4[tt] = 0.5 *(p.perm_sib_ce_ch4[tt] + p.perm_jul_ce_ch4[tt]) * (1 + p.perm_initial_c_stock_uncertainty/100)

        # calculate  for this specific year
        if is_first(t)
            for annual_year = 2015:(gettime(t))
                calc_PermafrostTotal(p, v, d, t, annual_year)
            end
        else
            for annual_year = (gettime(t-1)+1):(gettime(t))
                calc_PermafrostTotal(p, v, d, t, annual_year)
            end
        end
    end
end
