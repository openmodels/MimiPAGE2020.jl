@defcomp PermafrostTotal begin
    perm_sib_ce_co2 = Parameter(index=[time], unit="Mtonne CO2")
    perm_jul_ce_co2 = Parameter(index=[time], unit="Mtonne CO2")
    perm_sib_e_co2 = Parameter(index=[time], unit="MtonCO2/yr")
    perm_jul_e_co2 = Parameter(index=[time], unit="MtonCO2/yr")
    perm_sib_ce_ch4 = Parameter(index=[time], unit="Mtonne CH4")
    perm_jul_ce_ch4 = Parameter(index=[time], unit="Mtonne CH4")

    perm_initial_c_stock_uncertainty = Parameter(default=0.0)

    perm_tot_ce_co2 = Variable(index=[time], unit="Mtonne")
    perm_tot_e_co2 = Variable(index=[time], unit="Mtonne")
    perm_tot_ce_ch4 = Variable(index=[time], unit="Mtonne")

    function run_timestep(p, v, d, tt)
        # Cumulative emissions CO2 perm
        v.perm_tot_ce_co2[tt] = 0.5 *(p.perm_sib_ce_co2[tt] + p.perm_jul_ce_co2[tt]) * (1 + p.perm_initial_c_stock_uncertainty/100)
        # Annual emissions CO2 perm
        v.perm_tot_e_co2[tt] = 0.5 *(p.perm_sib_e_co2[tt] + p.perm_jul_e_co2[tt]) * (1 + p.perm_initial_c_stock_uncertainty/100)
        # Cumulative emissions CH4 perm
        v.perm_tot_ce_ch4[tt] = 0.5 *(p.perm_sib_ce_ch4[tt] + p.perm_jul_ce_ch4[tt]) * (1 + p.perm_initial_c_stock_uncertainty/100)
    end
end
