@defcomp PermafrostJULES begin
    rt_g = Parameter(index=[time],unit="degreeC")
    y_year_0 = Parameter(unit="year")
    y_year = Parameter(index=[time], unit="year")

    perm_jul_af = Parameter(default=1.9359078717122433)
    perm_jul_limit_t = Parameter(default=18.86448815404626)
    perm_jul_sens_slope_vs_t_co2 = Parameter(default=-0.12186871366342877)
    perm_jul_lag_slope_vs_t_co2 = Parameter(default=-0.6550115433585014)
    perm_jul_pow_slope_vs_t_co2 = Parameter(default=1.618876347278246)
    perm_jul_sens_c_co2 = Parameter(default=61867.779459651385)
    perm_jul_limit_c = Parameter(default=738145.3283931707)
    perm_jul_ce_c_co2_0 = Parameter(default=20040.99686065949)
    perm_jul_pow_c_co2 = Parameter(default=0.457030756829357)
    perm_jul_lag_c_co2 = Parameter(default=543.6163557759747)
    perm_jul_ch4_co2_c_ratio = Parameter(default=6.116162272246744)

    perm_jul_temp = Variable(index=[time], unit="degreeC")
    perm_jul_sens_c_co2_correct = Variable(index=[time])
    perm_jul_lag_c_co2_correct = Variable(index=[time])
    perm_jul_pow_c_co2_correct = Variable(index=[time])
    perm_jul_equilib_c_co2 = Variable(index=[time], unit="Mtonne C")
    perm_jul_ce_c_co2 = Variable(index=[time], unit="Mtonne C")
    perm_jul_ce_co2 = Variable(index=[time], unit="Mtonne CO2")
    perm_jul_e_co2 = Variable(index=[time], unit="MtonCO2/yr")
    perm_jul_ce_ch4 = Variable(index=[time], unit="Mtonne CH4")

    function run_timestep(p, v, d, tt)
        if is_first(tt)
            yp = p.y_year[tt] - p.y_year_0
        else
            yp = p.y_year[tt] - p.y_year[tt-1]
        end

        # Permafrost temperature
        v.perm_jul_temp[tt] = p.rt_g[tt] * p.perm_jul_af
        # Correction for perm sensitivity, CO2
        v.perm_jul_sens_c_co2_correct[tt] = (v.perm_jul_temp[tt]/(0.5*p.perm_jul_limit_t))^p.perm_jul_sens_slope_vs_t_co2
        # Correction for perm lag, CO2
        v.perm_jul_lag_c_co2_correct[tt] = (v.perm_jul_temp[tt]/(0.5*p.perm_jul_limit_t))^p.perm_jul_lag_slope_vs_t_co2
        # Correction for perm power, CO2
        v.perm_jul_pow_c_co2_correct[tt] = ifelse(1 + p.perm_jul_pow_slope_vs_t_co2 * (v.perm_jul_temp[tt] - 0.5*p.perm_jul_limit_t) /p.perm_jul_limit_t <= 0, 0.000001, 1 + p.perm_jul_pow_slope_vs_t_co2 * (v.perm_jul_temp[tt] - 0.5*p.perm_jul_limit_t) /p.perm_jul_limit_t)
        # Equilibrium perm cumul carbon, CO2
        v.perm_jul_equilib_c_co2[tt] = ifelse((p.perm_jul_sens_c_co2 * v.perm_jul_sens_c_co2_correct[tt]) * v.perm_jul_temp[tt] < p.perm_jul_limit_c, (p.perm_jul_sens_c_co2 * v.perm_jul_sens_c_co2_correct[tt]) * v.perm_jul_temp[tt], p.perm_jul_limit_c)
        # Released perm cumul carbon, CO2
        if is_first(tt)
            v.perm_jul_ce_c_co2[tt] = ((v.perm_jul_equilib_c_co2[tt] < p.perm_jul_ce_c_co2_0) ? p.perm_jul_ce_c_co2_0 : ((((v.perm_jul_equilib_c_co2[tt] - p.perm_jul_ce_c_co2_0)/p.perm_jul_limit_c)^(1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) < (1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) * yp / (p.perm_jul_lag_c_co2*v.perm_jul_lag_c_co2_correct[tt])) ? v.perm_jul_equilib_c_co2[tt] : (v.perm_jul_equilib_c_co2[tt] - p.perm_jul_limit_c * ((((v.perm_jul_equilib_c_co2[tt] - p.perm_jul_ce_c_co2_0)/p.perm_jul_limit_c)^(1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) - (1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) * yp / (p.perm_jul_lag_c_co2*v.perm_jul_lag_c_co2_correct[tt]))^(1/(1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]))))))
        else
            v.perm_jul_ce_c_co2[tt] = ((v.perm_jul_equilib_c_co2[tt] < v.perm_jul_ce_c_co2[tt-1]) ? v.perm_jul_ce_c_co2[tt-1] : ((((v.perm_jul_equilib_c_co2[tt] - v.perm_jul_ce_c_co2[tt-1])/p.perm_jul_limit_c)^(1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) < (1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) * yp / (p.perm_jul_lag_c_co2*v.perm_jul_lag_c_co2_correct[tt])) ? v.perm_jul_equilib_c_co2[tt] : (v.perm_jul_equilib_c_co2[tt] - p.perm_jul_limit_c * ((((v.perm_jul_equilib_c_co2[tt] - v.perm_jul_ce_c_co2[tt-1])/p.perm_jul_limit_c)^(1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) - (1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]) * yp / (p.perm_jul_lag_c_co2*v.perm_jul_lag_c_co2_correct[tt]))^(1/(1-(1+p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]))))))
        end
        # Released perm cumulative CO2
        v.perm_jul_ce_co2[tt] = v.perm_jul_ce_c_co2[tt] * (44/12)
        # Annual emissions CO2 perm
        v.perm_jul_e_co2[tt] = (44/12) * (p.perm_jul_limit_c / (p.perm_jul_lag_c_co2 * v.perm_jul_lag_c_co2_correct[tt])) * (ifelse(v.perm_jul_equilib_c_co2[tt] > v.perm_jul_ce_c_co2[tt], ((v.perm_jul_equilib_c_co2[tt] - v.perm_jul_ce_c_co2[tt])/p.perm_jul_limit_c)^((1 + p.perm_jul_pow_c_co2)*v.perm_jul_pow_c_co2_correct[tt]), 0))
        # Released perm cumulative CH4
        v.perm_jul_ce_ch4[tt] = v.perm_jul_ce_c_co2[tt] * (p.perm_jul_ch4_co2_c_ratio/100) * (16/12)
    end
end
