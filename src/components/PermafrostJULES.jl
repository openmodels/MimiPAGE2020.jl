@defcomp PermafrostJULES begin
    rt_g = Parameter(index=[time],unit="degC")

    perm_jul_ce_co2 = Variable(index=[time], unit="Mtonne CO2")
    perm_jul_e_co2 = Variable(index=[time], unit="MtonCO2/yr")
    perm_jul_ce_ch4 = Variable(index=[time], unit="Mtonne CH4")

    function run_timestep(p, v, d, tt)
        # Permafrost temperature
        perm_jul_temp = p.rt_g[tt] * perm_jul_af
        # Correction for perm sensitivity, CO2
        perm_jul_sens_c_co2_correct[tt] = (perm_jul_temp/(0.5*perm_jul_limit_t))^perm_jul_sens_slope_vs_t_co2
        # Correction for perm lag, CO2
        perm_jul_lag_c_co2_correct[tt] = (perm_jul_temp/(0.5*perm_jul_limit_t))^perm_jul_lag_slope_vs_t_co2
        # Correction for perm power, CO2
        perm_jul_pow_c_co2_correct[tt] = ifelse(1 + perm_jul_pow_slope_vs_t_co2 * (perm_jul_temp - 0.5*perm_jul_limit_t) /perm_jul_limit_t <= 0, 0.000001, 1 + perm_jul_pow_slope_vs_t_co2 * (perm_jul_temp - 0.5*perm_jul_limit_t) /perm_jul_limit_t)
        # Equilibrium perm cumul carbon, CO2
        perm_jul_equilib_c_co2[tt] = ifelse((perm_jul_sens_c_co2 * perm_jul_sens_c_co2_correct) * perm_jul_temp < perm_jul_limit_c, (perm_jul_sens_c_co2 * perm_jul_sens_c_co2_correct) * perm_jul_temp, perm_jul_limit_c)
        # Released perm cumul carbon, CO2
        perm_jul_ce_c_co2[tt] = ifelse(perm_jul_equilib_c_co2_1 <  perm_jul_ce_c_co2_0, perm_jul_ce_c_co2_0, ifelse( ((perm_jul_equilib_c_co2_1 - perm_jul_ce_c_co2_0)/perm_jul_limit_c)^(1-(1+perm_jul_pow_c_co2)*perm_jul_pow_c_co2_correct_1) < (1-(1+perm_jul_pow_c_co2)*perm_jul_pow_c_co2_correct_1) * yp_1 / (perm_jul_lag_c_co2*perm_jul_lag_c_co2_correct_1), perm_jul_equilib_c_co2_1, ( perm_jul_equilib_c_co2_1 - perm_jul_limit_c * ( ( ((perm_jul_equilib_c_co2_1 - perm_jul_ce_c_co2_0)/perm_jul_limit_c)^(1-(1+perm_jul_pow_c_co2)*perm_jul_pow_c_co2_correct_1) - (1-(1+perm_jul_pow_c_co2)*perm_jul_pow_c_co2_correct_1) * yp_1 / (perm_jul_lag_c_co2*perm_jul_lag_c_co2_correct_1) )^( 1/(1-(1+perm_jul_pow_c_co2)*perm_jul_pow_c_co2_correct_1) ) ) ) ) )
        # Released perm cumulative CO2
        perm_jul_ce_co2[tt] = perm_jul_ce_c_co2 * (44/12)
        # Annual emissions CO2 perm
        perm_jul_e_co2[tt] = (44/12) * (perm_jul_limit_c / (perm_jul_lag_c_co2 * perm_jul_lag_c_co2_correct)) * ( ifelse(perm_jul_equilib_c_co2 > perm_jul_ce_c_co2, ((perm_jul_equilib_c_co2 - perm_jul_ce_c_co2)/perm_jul_limit_c)^((1 + perm_jul_pow_c_co2)*perm_jul_pow_c_co2_correct), 0) )
        # Released perm cumulative CH4
        perm_jul_ce_ch4[tt] = perm_jul_ce_c_co2 * (perm_jul_ch4_co2_c_ratio/100) * (16/12)
    end
end
