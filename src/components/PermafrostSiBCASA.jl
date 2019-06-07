@defcomp PermafrostSiBCASA begin
    rt_g = Parameter(index=[time],unit="degC")

    PERM_SIB_AF = Parameter(default=1.8755694887303616) # Amplification factor for permafrost regions
    PERM_SIB_SENS_C_CO2 = Parameter(default=31939.74044307217) # Sensitivity for cumulative carbon emissions, CO2
    PERM_SIB_LAG_C_CO2 = Parameter(default=206.28841306311747) # Time lag for cumulative carbon emissions, CO2
    PERM_SIB_POW_C_CO2 = Parameter(default=0.2589907164292725) # Nonlinear power for cumulative carbon emissions, CO2
    PERM_SIB_SENS_C_CH4 = Parameter(default=2294.237641605309) # Sensitivity for cumulative carbon emissions, CH4
    PERM_SIB_LAG_C_CH4 = Parameter(default=61.693785559934845) # Time lag for cumulative carbon emissions, CH4
    PERM_SIB_POW_C_CH4 = Parameter(default=0.2510548621108904) # Nonlinear power for cumulative carbon emissions, CH4

    function run_timestep(p, v, d, tt)
        if is_first(t)
            # Permafrost temperature
            PERM_SIB_TEMP_0 = RT_G_0 * p.PERM_SIB_AF
            # Correction for perm sensitivity, CO2
            PERM_SIB_SENS_C_CO2_CORRECT_0 = IF(1 + PERM_SIB_SENS_SLOPE_VS_T_CO2 * (PERM_SIB_TEMP_0 - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T <=0, 0.000001, 1 + PERM_SIB_SENS_SLOPE_VS_T_CO2 * (PERM_SIB_TEMP_0 - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)
            # Correction for perm lag, CO2
            PERM_SIB_LAG_C_CO2_CORRECT_0 = IF(1 + PERM_SIB_LAG_SLOPE_VS_T_CO2 * (PERM_SIB_TEMP_0 - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T <=0, 0.000001, 1 + PERM_SIB_LAG_SLOPE_VS_T_CO2 * (PERM_SIB_TEMP_0 - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)
            # Correction for perm power, CO2
            PERM_SIB_POW_C_CO2_CORRECT_0 = IF(1 + PERM_SIB_POW_SLOPE_VS_T_CO2 * (PERM_SIB_TEMP_0 - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T <=0, 0.000001, 1 + PERM_SIB_POW_SLOPE_VS_T_CO2 * (PERM_SIB_TEMP_0 - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)
            # Equilibrium perm cumul carbon, CO2
            PERM_SIB_EQUILIB_C_CO2_0 = (PERM_SIB_SENS_C_CO2 * PERM_SIB_SENS_C_CO2_CORRECT_0) * PERM_SIB_TEMP_0
            # Annual emissions CO2 perm
            PERM_SIB_E_CO2_0 = (44/12) * (PERM_SIB_LIMIT_C / (p.PERM_SIB_LAG_C_CO2 * PERM_SIB_LAG_C_CO2_CORRECT_0)) * ( IF(PERM_SIB_EQUILIB_C_CO2_0 >PERM_SIB_CE_C_CO2_0, ((PERM_SIB_EQUILIB_C_CO2_0 - PERM_SIB_CE_C_CO2_0)/PERM_SIB_LIMIT_C)^((1 + p.PERM_SIB_POW_C_CO2)*PERM_SIB_POW_C_CO2_CORRECT_0), 0) )

            # Correction for perm sensitivity, CH4
            PERM_SIB_SENS_C_CH4_CORRECT_0 = (PERM_SIB_TEMP_0 /(0.5*PERM_SIB_LIMIT_T))^PERM_SIB_SENS_SLOPE_VS_T_CH4
            # Correction for perm lag, CH4
            PERM_SIB_LAG_C_CH4_CORRECT_0
            # Correction for perm power, CH4
            PERM_SIB_POW_C_CH4_CORRECT_0
        else
            # Permafrost temperature
            perm_sib_temp[tt] = rt_g * p.PERM_SIB_AF
            # Correction for perm sensitivity, CO2
            perm_sib_sens_c_co2_correct[tt] = IF(1 + PERM_SIB_SENS_SLOPE_VS_T_CO2 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T <= 0, 0.000001, 1 + PERM_SIB_SENS_SLOPE_VS_T_CO2 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)
            # Correction for perm lag, CO2
            perm_sib_lag_c_co2_correct[tt] = PERM_SIB_LAG_SLOPE_VS_T_CO2 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)+perm_sib_lag_c_co2_correct_1
            # Correction for perm power, CO2
            perm_sib_pow_c_co2_correct[tt] = IF(1 + PERM_SIB_POW_SLOPE_VS_T_CO2 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T <= 0, 0.000001, 1 + PERM_SIB_POW_SLOPE_VS_T_CO2 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)+perm_sib_pow_c_co2_correct_1
            # Equilibrium perm cumul carbon, CO2
            perm_sib_equilib_c_co2[tt] = IF((p.PERM_SIB_SENS_C_CO2 * perm_sib_sens_c_co2_correct) * perm_sib_temp < PERM_SIB_LIMIT_C, (p.PERM_SIB_SENS_C_CO2 * perm_sib_sens_c_co2_correct) * perm_sib_temp, PERM_SIB_LIMIT_C)
            # Released perm cumul carbon, CO2
            perm_sib_ce_c_co2[tt] = IF(perm_sib_equilib_c_co2_1 <  PERM_SIB_CE_C_CO2_0, PERM_SIB_CE_C_CO2_0, IF( ((perm_sib_equilib_c_co2_1 - PERM_SIB_CE_C_CO2_0)/PERM_SIB_LIMIT_C)^(1-(1+p.PERM_SIB_POW_C_CO2)*perm_sib_pow_c_co2_correct_1) < (1-(1+p.PERM_SIB_POW_C_CO2)*perm_sib_pow_c_co2_correct_1) * YP_1 / (p.PERM_SIB_LAG_C_CO2*perm_sib_lag_c_co2_correct_1), perm_sib_equilib_c_co2_1, ( perm_sib_equilib_c_co2_1 - PERM_SIB_LIMIT_C * ( ( ((perm_sib_equilib_c_co2_1 - PERM_SIB_CE_C_CO2_0)/PERM_SIB_LIMIT_C)^(1-(1+p.PERM_SIB_POW_C_CO2)*perm_sib_pow_c_co2_correct_1) - (1-(1+p.PERM_SIB_POW_C_CO2)*perm_sib_pow_c_co2_correct_1) * YP_1 / (p.PERM_SIB_LAG_C_CO2*perm_sib_lag_c_co2_correct_1) )^( 1/(1-(1+p.PERM_SIB_POW_C_CO2)*perm_sib_pow_c_co2_correct_1) ) ) ) ) )
            # Released perm cumulative CO2
            # = perm_sib_ce_c_co2 * (44/12)
            # Annual emissions CO2 perm
            PERM_SIB_E_CO2[tt] = (44/12) * (PERM_SIB_LIMIT_C / (p.PERM_SIB_LAG_C_CO2 * perm_sib_lag_c_co2_correct)) * ( IF(perm_sib_equilib_c_co2 > perm_sib_ce_c_co2, ((perm_sib_equilib_c_co2 - perm_sib_ce_c_co2)/PERM_SIB_LIMIT_C)^((1 + p.PERM_SIB_POW_C_CO2)*perm_sib_pow_c_co2_correct), 0) )

            # Correction for perm sensitivity, CH4
            perm_sib_sens_c_ch4_correct[tt] = (perm_sib_temp/(0.5*PERM_SIB_LIMIT_T))^PERM_SIB_SENS_SLOPE_VS_T_CH4
            # Correction for perm lag, CH4
            perm_sib_lag_c_ch4_correct[tt] = (perm_sib_temp/(0.5*PERM_SIB_LIMIT_T))^PERM_SIB_LAG_SLOPE_VS_T_CH4
            # Correction for perm power, CH4
            perm_sib_pow_c_ch4_correct[tt] = IF(1 + PERM_SIB_POW_SLOPE_VS_T_CH4 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T <= 0, 0.000001, 1 + PERM_SIB_POW_SLOPE_VS_T_CH4 * (perm_sib_temp - 0.5*PERM_SIB_LIMIT_T) /PERM_SIB_LIMIT_T)
            # Equilibrium perm cumul carbon, CH4
            perm_sib_equilib_c_ch4[tt] = IF((p.PERM_SIB_SENS_C_CH4 * perm_sib_sens_c_ch4_correct) * perm_sib_temp < PERM_SIB_LIMIT_C, (p.PERM_SIB_SENS_C_CH4 * perm_sib_sens_c_ch4_correct) * perm_sib_temp, PERM_SIB_LIMIT_C)
            # Released perm cumulative CH4
            perm_sib_ce_ch4[tt] = perm_sib_ce_c_ch4 * (16/12)
        end
    end
end

function addpermafrost(model::Model, use_permafrost::Bool)
    permafrost = add_comp!(model, Permafrost)

    if use_permafrost
        permafrost[:permtce0_permafrostemissions0] = 934.2010230392067
        permafrost[:permtce_permafrostemissions] = readpagedata(model, "data/perm_tot_ce_ch4.csv")
    else
        permafrost[:permtce0_permafrostemissions0] = 0
        permafrost[:permtce_permafrostemissions] = zeros(10)
    end

    permafrost
end

function addPermafrostSiBASA(model::Model)

end
