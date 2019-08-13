@defcomp PermafrostSiBCASA begin
    rt_g = Parameter(index=[time],unit="degreeC")
    y_year_0 = Parameter(unit="year")
    y_year = Parameter(index=[time], unit="year")

    perm_sib_af = Parameter(default=1.8755694887303616) # Amplification factor for permafrost regions
    perm_sib_sens_c_co2 = Parameter(default=31939.74044307217) # Sensitivity for cumulative carbon emissions, CO2
    perm_sib_lag_c_co2 = Parameter(default=61.693785559934845) # Time lag for cumulative carbon emissions, CO2
    perm_sib_pow_c_co2 = Parameter(default=0.2589907164292725) # Nonlinear power for cumulative carbon emissions, CO2
    perm_sib_sens_c_ch4 = Parameter(default=2294.237641605309) # Sensitivity for cumulative carbon emissions, CH4
    perm_sib_lag_c_ch4 = Parameter(default=206.28841306311747) # Time lag for cumulative carbon emissions, CH4
    perm_sib_pow_c_ch4 = Parameter(default=0.2510548621108904) # Nonlinear power for cumulative carbon emissions, CH4
    perm_sib_sens_slope_vs_t_co2 = Parameter(default=1.3953528485263331)
    perm_sib_limit_t = Parameter(default=22.206606297204385)
    perm_sib_lag_slope_vs_t_co2 = Parameter(default=0.8292129951283947)
    perm_sib_pow_slope_vs_t_co2 = Parameter(default=-0.03334709744835228)
    perm_sib_limit_c = Parameter(default=560000.0)
    perm_sib_ce_c_co2_0 = Parameter(default=3764.052934735)
    perm_sib_ce_co2_0 = Parameter(default=13801.527427361667)
    perm_sib_sens_slope_vs_t_ch4 = Parameter(default=-0.061634027375886635)
    perm_sib_lag_slope_vs_t_ch4 = Parameter(default=-2.5752200686097426)
    perm_sib_pow_slope_vs_t_ch4 = Parameter(default=1.3992129787187544)
    perm_sib_pow_c_ch4 = Parameter(default=0.2510548621108904)
    perm_sib_ce_c_ch4_0 = Parameter(default=175.56164558499998)

    perm_sib_temp = Variable(index=[time], unit="degreeC")
    perm_sib_sens_c_co2_correct = Variable(index=[time])
    perm_sib_lag_c_co2_correct = Variable(index=[time])
    perm_sib_pow_c_co2_correct = Variable(index=[time])
    perm_sib_equilib_c_co2 = Variable(index=[time])
    perm_sib_ce_c_co2 = Variable(index=[time], unit="MtonneC")
    perm_sib_ce_co2 = Variable(index=[time], unit="Mtonne CO2")
    perm_sib_e_co2 = Variable(index=[time], unit="MtonCO2/yr")
    perm_sib_sens_c_ch4_correct = Variable(index=[time])
    perm_sib_lag_c_ch4_correct = Variable(index=[time])
    perm_sib_pow_c_ch4_correct = Variable(index=[time])
    perm_sib_equilib_c_ch4 = Variable(index=[time], unit="Mtonne C")
    perm_sib_ce_c_ch4 = Variable(index=[time], unit="Mtonne C")
    perm_sib_ce_ch4 = Variable(index=[time], unit="Mtonne CH4")

    function run_timestep(p, v, d, tt)
        if is_first(tt)
            yp = p.y_year[tt] - p.y_year_0
        else
            yp = p.y_year[tt] - p.y_year[tt-1]
        end

        # # Permafrost temperature
        # perm_sib_temp_0 = rt_g_0 * p.perm_sib_af
        # # Correction for perm sensitivity, CO2
        # perm_sib_sens_c_co2_correct_0 = if(1 + perm_sib_sens_slope_vs_t_co2 * (perm_sib_temp_0 - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <=0, 0.000001, 1 + perm_sib_sens_slope_vs_t_co2 * (perm_sib_temp_0 - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        # # Correction for perm lag, CO2
        # perm_sib_lag_c_co2_correct_0 = if(1 + p.perm_sib_lag_slope_vs_t_co2 * (perm_sib_temp_0 - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <=0, 0.000001, 1 + p.perm_sib_lag_slope_vs_t_co2 * (perm_sib_temp_0 - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        # # Correction for perm power, CO2
        # perm_sib_pow_c_co2_correct_0 = if(1 + p.perm_sib_pow_slope_vs_t_co2 * (perm_sib_temp_0 - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <=0, 0.000001, 1 + p.perm_sib_pow_slope_vs_t_co2 * (perm_sib_temp_0 - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        # # Equilibrium perm cumul carbon, CO2
        # perm_sib_equilib_c_co2_0 = (perm_sib_sens_c_co2 * perm_sib_sens_c_co2_correct_0) * perm_sib_temp_0
        # # Annual emissions CO2 perm
        # perm_sib_e_co2_0 = (44/12) * (p.perm_sib_limit_c / (p.perm_sib_lag_c_co2 * perm_sib_lag_c_co2_correct_0)) * ( if(perm_sib_equilib_c_co2_0 >p.perm_sib_ce_co2_0, ((perm_sib_equilib_c_co2_0 - p.perm_sib_ce_co2_0)/p.perm_sib_limit_c)^((1 + p.perm_sib_pow_c_co2)*perm_sib_pow_c_co2_correct_0), 0) )

        # # Correction for perm sensitivity, CH4
        # perm_sib_sens_c_ch4_correct_0 = (perm_sib_temp_0 /(0.5*p.perm_sib_limit_t))^p.perm_sib_sens_slope_vs_t_ch4
        # # Correction for perm lag, CH4
        # perm_sib_lag_c_ch4_correct_0
        # # Correction for perm power, CH4
        # perm_sib_pow_c_ch4_correct_0

        # Permafrost temperature
        v.perm_sib_temp[tt] = p.rt_g[tt] * p.perm_sib_af
        # Correction for perm sensitivity, CO2
        v.perm_sib_sens_c_co2_correct[tt] = ifelse(1 + p.perm_sib_sens_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <= 0, 0.000001, 1 + p.perm_sib_sens_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        # Correction for perm lag, CO2
        v.perm_sib_lag_c_co2_correct[tt] = ifelse(1 + p.perm_sib_lag_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <= 0, 0.000001, 1 + p.perm_sib_lag_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        # Correction for perm power, CO2
        if is_first(tt)
            v.perm_sib_pow_c_co2_correct[tt] = ifelse(1 + p.perm_sib_pow_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <= 0, 0.000001, 1 + p.perm_sib_pow_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        else
            v.perm_sib_pow_c_co2_correct[tt] = ifelse(1 + p.perm_sib_pow_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <= 0, 0.000001, 1 + p.perm_sib_pow_slope_vs_t_co2 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        end
        # Equilibrium perm cumul carbon, CO2
        v.perm_sib_equilib_c_co2[tt] = ifelse((p.perm_sib_sens_c_co2 * v.perm_sib_sens_c_co2_correct[tt]) * v.perm_sib_temp[tt] < p.perm_sib_limit_c, (p.perm_sib_sens_c_co2 * v.perm_sib_sens_c_co2_correct[tt]) * v.perm_sib_temp[tt], p.perm_sib_limit_c)
        # Released perm cumul carbon, CO2
        if is_first(tt)
            v.perm_sib_ce_c_co2[tt] = ((v.perm_sib_equilib_c_co2[tt] <  p.perm_sib_ce_c_co2_0) ? p.perm_sib_ce_c_co2_0 : (( ((v.perm_sib_equilib_c_co2[tt] - p.perm_sib_ce_c_co2_0)/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) < (1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) * yp / (p.perm_sib_lag_c_co2*v.perm_sib_lag_c_co2_correct[tt])) ? v.perm_sib_equilib_c_co2[tt] : ( v.perm_sib_equilib_c_co2[tt] - p.perm_sib_limit_c * ( ( ((v.perm_sib_equilib_c_co2[tt] - p.perm_sib_ce_c_co2_0)/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) - (1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) * yp / (p.perm_sib_lag_c_co2*v.perm_sib_lag_c_co2_correct[tt]) )^( 1/(1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) ) ) ) ) )
        else
            v.perm_sib_ce_c_co2[tt] = ((v.perm_sib_equilib_c_co2[tt] <  v.perm_sib_ce_c_co2[tt-1]) ? v.perm_sib_ce_c_co2[tt-1] : (( ((v.perm_sib_equilib_c_co2[tt] - v.perm_sib_ce_c_co2[tt-1])/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) < (1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) * yp / (p.perm_sib_lag_c_co2*v.perm_sib_lag_c_co2_correct[tt])) ? v.perm_sib_equilib_c_co2[tt] : ( v.perm_sib_equilib_c_co2[tt] - p.perm_sib_limit_c * ( ( ((v.perm_sib_equilib_c_co2[tt] - v.perm_sib_ce_c_co2[tt-1])/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) - (1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) * yp / (p.perm_sib_lag_c_co2*v.perm_sib_lag_c_co2_correct[tt]) )^( 1/(1-(1+p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) ) ) ) ) )
        end
        # Released perm cumulative CO2
        v.perm_sib_ce_co2[tt] = v.perm_sib_ce_c_co2[tt] * (44. / 12.)
# Annual emissions CO2 perm
        v.perm_sib_e_co2[tt] = (44/12) * (p.perm_sib_limit_c / (p.perm_sib_lag_c_co2 * v.perm_sib_lag_c_co2_correct[tt])) * ( ((v.perm_sib_equilib_c_co2[tt] > v.perm_sib_ce_c_co2[tt]) ? ((v.perm_sib_equilib_c_co2[tt] - v.perm_sib_ce_c_co2[tt])/p.perm_sib_limit_c)^((1 + p.perm_sib_pow_c_co2)*v.perm_sib_pow_c_co2_correct[tt]) : 0) )

        # Correction for perm sensitivity, CH4
        v.perm_sib_sens_c_ch4_correct[tt] = (v.perm_sib_temp[tt]/(0.5*p.perm_sib_limit_t))^p.perm_sib_sens_slope_vs_t_ch4
        # Correction for perm lag, CH4
        v.perm_sib_lag_c_ch4_correct[tt] = (v.perm_sib_temp[tt]/(0.5*p.perm_sib_limit_t))^p.perm_sib_lag_slope_vs_t_ch4
        # Correction for perm power, CH4
        v.perm_sib_pow_c_ch4_correct[tt] = ifelse(1 + p.perm_sib_pow_slope_vs_t_ch4 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t <= 0, 0.000001, 1 + p.perm_sib_pow_slope_vs_t_ch4 * (v.perm_sib_temp[tt] - 0.5*p.perm_sib_limit_t) /p.perm_sib_limit_t)
        # Equilibrium perm cumul carbon, CH4
        v.perm_sib_equilib_c_ch4[tt] = ifelse((p.perm_sib_sens_c_ch4 * v.perm_sib_sens_c_ch4_correct[tt]) * v.perm_sib_temp[tt] < p.perm_sib_limit_c, (p.perm_sib_sens_c_ch4 * v.perm_sib_sens_c_ch4_correct[tt]) * v.perm_sib_temp[tt], p.perm_sib_limit_c)
        # Released perm cumul carbon, CH4
        if is_first(tt)
            v.perm_sib_ce_c_ch4[tt] = ((v.perm_sib_equilib_c_ch4[tt] <  p.perm_sib_ce_c_ch4_0) ? p.perm_sib_ce_c_ch4_0 : (( ((v.perm_sib_equilib_c_ch4[tt] - p.perm_sib_ce_c_ch4_0)/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) < (1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) * yp / (p.perm_sib_lag_c_ch4*v.perm_sib_lag_c_ch4_correct[tt])) ? v.perm_sib_equilib_c_ch4[tt] : ( v.perm_sib_equilib_c_ch4[tt] - p.perm_sib_limit_c * ( ( ((v.perm_sib_equilib_c_ch4[tt] - p.perm_sib_ce_c_ch4_0)/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) - (1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) * yp / (p.perm_sib_lag_c_ch4*v.perm_sib_lag_c_ch4_correct[tt]) )^( 1/(1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) ) ) ) ) )
        else
            v.perm_sib_ce_c_ch4[tt] = ((v.perm_sib_equilib_c_ch4[tt] <  v.perm_sib_ce_c_ch4[tt-1]) ? v.perm_sib_ce_c_ch4[tt-1] : (( ((v.perm_sib_equilib_c_ch4[tt] - v.perm_sib_ce_c_ch4[tt-1])/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) < (1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) * yp / (p.perm_sib_lag_c_ch4*v.perm_sib_lag_c_ch4_correct[tt])) ? v.perm_sib_equilib_c_ch4[tt] : ( v.perm_sib_equilib_c_ch4[tt] - p.perm_sib_limit_c * ( ( ((v.perm_sib_equilib_c_ch4[tt] - v.perm_sib_ce_c_ch4[tt-1])/p.perm_sib_limit_c)^(1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) - (1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) * yp / (p.perm_sib_lag_c_ch4*v.perm_sib_lag_c_ch4_correct[tt]) )^( 1/(1-(1+p.perm_sib_pow_c_ch4)*v.perm_sib_pow_c_ch4_correct[tt]) ) ) ) ) )
        end
        # Released perm cumulative CH4
        v.perm_sib_ce_ch4[tt] = v.perm_sib_ce_c_ch4[tt] * (16/12)
    end
end
