@defcomp PermafrostJULES begin
    rt_g = Parameter(index=[time],unit="degC")

    function run_timestep(p, v, d, tt)
        # Permafrost temperature
        perm_jul_temp = p.rt_g[tt] * PERM_JUL_AF
        # Correction for perm sensitivity, CO2
        perm_jul_sens_c_co2_correct[tt] = (perm_jul_temp/(0.5*PERM_JUL_LIMIT_T))^PERM_JUL_SENS_SLOPE_VS_T_CO2
        # Correction for perm lag, CO2
        perm_jul_lag_c_co2_correct[tt] = (perm_jul_temp/(0.5*PERM_JUL_LIMIT_T))^PERM_JUL_LAG_SLOPE_VS_T_CO2
        # Correction for perm power, CO2
        perm_jul_pow_c_co2_correct[tt] = IF(1 + PERM_JUL_POW_SLOPE_VS_T_CO2 * (perm_jul_temp - 0.5*PERM_JUL_LIMIT_T) /PERM_JUL_LIMIT_T <= 0, 0.000001, 1 + PERM_JUL_POW_SLOPE_VS_T_CO2 * (perm_jul_temp - 0.5*PERM_JUL_LIMIT_T) /PERM_JUL_LIMIT_T)
        # Equilibrium perm cumul carbon, CO2
        perm_jul_equilib_c_co2[tt] = IF((PERM_JUL_SENS_C_CO2 * perm_jul_sens_c_co2_correct) * perm_jul_temp < PERM_JUL_LIMIT_C, (PERM_JUL_SENS_C_CO2 * perm_jul_sens_c_co2_correct) * perm_jul_temp, PERM_JUL_LIMIT_C)
        # Released perm cumul carbon, CO2
        perm_jul_ce_c_co2[tt] = IF(perm_jul_equilib_c_co2_1 <  PERM_JUL_CE_C_CO2_0, PERM_JUL_CE_C_CO2_0, IF( ((perm_jul_equilib_c_co2_1 - PERM_JUL_CE_C_CO2_0)/PERM_JUL_LIMIT_C)^(1-(1+PERM_JUL_POW_C_CO2)*perm_jul_pow_c_co2_correct_1) < (1-(1+PERM_JUL_POW_C_CO2)*perm_jul_pow_c_co2_correct_1) * YP_1 / (PERM_JUL_LAG_C_CO2*perm_jul_lag_c_co2_correct_1), perm_jul_equilib_c_co2_1, ( perm_jul_equilib_c_co2_1 - PERM_JUL_LIMIT_C * ( ( ((perm_jul_equilib_c_co2_1 - PERM_JUL_CE_C_CO2_0)/PERM_JUL_LIMIT_C)^(1-(1+PERM_JUL_POW_C_CO2)*perm_jul_pow_c_co2_correct_1) - (1-(1+PERM_JUL_POW_C_CO2)*perm_jul_pow_c_co2_correct_1) * YP_1 / (PERM_JUL_LAG_C_CO2*perm_jul_lag_c_co2_correct_1) )^( 1/(1-(1+PERM_JUL_POW_C_CO2)*perm_jul_pow_c_co2_correct_1) ) ) ) ) )
        # Released perm cumulative CO2
        perm_jul_ce_co2[tt] = perm_jul_ce_c_co2 * (44/12)
        # Annual emissions CO2 perm
        perm_jul_e_co2[tt] = (44/12) * (PERM_JUL_LIMIT_C / (PERM_JUL_LAG_C_CO2 * perm_jul_lag_c_co2_correct)) * ( IF(perm_jul_equilib_c_co2 > perm_jul_ce_c_co2, ((perm_jul_equilib_c_co2 - perm_jul_ce_c_co2)/PERM_JUL_LIMIT_C)^((1 + PERM_JUL_POW_C_CO2)*perm_jul_pow_c_co2_correct), 0) )
        # Released perm cumulative CH4
        perm_jul_ce_ch4[tt] = perm_jul_ce_c_co2 * (PERM_JUL_CH4_CO2_C_RATIO/100) * (16/12)
    end
end
