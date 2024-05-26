using Arrow

include("../utils/country_tools.jl")

@defcomp RFFSPScenario begin
    country = Index()

    model = Parameter{Model}()
    rffsp_draw = Parameter{Int64}()

    # Scenario values
    gpcgrw_gdppcgrowthrate = Variable(index=[time, country], unit="%/year")
    popgrw_populationgrowth = Variable(index=[time, country], unit="%/year")
    grw_gdpgrowthrate = Variable(index=[time, country], unit="%/year")

    # Input RCP values
    grw_gdpgrowthrate_rcp = Parameter(index=[time, region], unit="%/year")
    er_CO2emissionsgrowth_rcp = Parameter(index=[time,region], unit="%")
    er_CH4emissionsgrowth_rcp = Parameter(index=[time,region], unit="%")
    er_N2Oemissionsgrowth_rcp = Parameter(index=[time,region], unit="%")
    er_LGemissionsgrowth_rcp = Parameter(index=[time,region], unit="%")
    pse_sulphatevsbase_rcp = Parameter(index=[time, region], unit="%")

    # Kaya-adjusted emissions
    er_CO2emissionsgrowth = Variable(index=[time,region], unit="%")
    er_CH4emissionsgrowth = Variable(index=[time,region], unit="%")
    er_N2Oemissionsgrowth = Variable(index=[time,region], unit="%")
    er_LGemissionsgrowth = Variable(index=[time,region], unit="%")
    pse_sulphatevsbase = Variable(index=[time, region], unit="%")

    function init(pp, vv, dd)
        if pp.rffsp_draw == 0
            df = Arrow.Table(datapath("rffsp/grows-mean.feather")) |> DataFrame
        else
            df = Arrow.Table(datapath("rffsp/grows-$(((pp.rffsp_draw-1) ÷ 1000)+1).feather")) |> DataFrame
            df = df[df.num .== pp.rffsp_draw, :]
        end

        vv.popgrw_populationgrowth[:, :] = readcountrydata_it_const(pp.model, df, :ISO, :period, "pop.grow")
        vv.gpcgrw_populationgrowth[:, :] = readcountrydata_it_const(pp.model, df, :ISO, :period, "gdppc.grow")
    end

    function run_timestep(pp, vv, dd, tt)
        vv.grw_gdpgrowthrate[tt, :] = vv.popgrw_populationgrowth[tt, :] .* vv.gpcgrw_gdppcgrowthrate[tt, :]

        ## Emit = Emit_SSP * (GDP_RFF / GDP_SSP)
        ## grow Emit = grow Emit_SSP + grow GDP_RFF - grow GDP_SSP
        grw_gdpgrowthrate_region = countrytoregion(pp.model, mean, vv.grw_gdpgrowthrate[tt, :])

        if is_first(tt)
            prev_erco2 = 100.
            prev_erch4 = 100.
            prev_ern2o = 100.
            prev_erlg = 100.
            prev_pse = 100.
            deltat = p.y_year[tt] - p.y_year_0
        else
            prev_erco2 = pp.er_CO2emissionsgrowth_rcp[tt-1, :]
            prev_erch4 = pp.er_CH4emissionsgrowth_rcp[tt-1, :]
            prev_ern2o = pp.er_N2Oemissionsgrowth_rcp[tt-1, :]
            prev_erlg = pp.er_LGemissionsgrowth_rcp[tt-1, :]
            prev_pse = pp.pse_sulphatevsbase_rcp[tt-1, :]
            deltat = p.y_year[tt] - p.y_year[tt-1]
        end

        er_CO2emissionsgrowth_rate = log(pp.er_CO2emissionsgrowth_rcp[tt, :] / prev_erco2) / deltat + grw_gdpgrowthrate_region - pp.grw_gdpgrowthrate_rcp[tt, :]
        vv.er_CO2emissionsgrowth = prev_erco2 * exp(er_CO2emissionsgrowth_rate * deltat)

        er_CH4emissionsgrowth_rate = log(pp.er_CH4emissionsgrowth_rcp[tt, :] / prev_erch4) / deltat + grw_gdpgrowthrate_region - pp.grw_gdpgrowthrate_rcp[tt, :]
        vv.er_CH4emissionsgrowth = prev_erch4 * exp(er_CH4emissionsgrowth_rate * deltat)

        er_N2Oemissionsgrowth_rate = log(pp.er_N2Oemissionsgrowth_rcp[tt, :] / prev_ern2o) / deltat + grw_gdpgrowthrate_region - pp.grw_gdpgrowthrate_rcp[tt, :]
        vv.er_N2Oemissionsgrowth = prev_ern2o * exp(er_N2Oemissionsgrowth_rate * deltat)

        er_LGemissionsgrowth_rate = log(pp.er_LGemissionsgrowth_rcp[tt, :] / prev_erlg) / deltat + grw_gdpgrowthrate_region - pp.grw_gdpgrowthrate_rcp[tt, :]
        vv.er_LGemissionsgrowth = prev_erlg * exp(er_LGemissionsgrowth_rate * deltat)

        pse_sulphatevsbase_rate = log(pp.pse_sulphatevsbase_rcp[tt, :] / prev_pse) / deltat + grw_gdpgrowthrate_region - pp.grw_gdpgrowthrate_rcp[tt, :]
        vv.pse_sulphatevsbase = prev_erco2 * exp(pse_sulphatevsbase_rate * deltat)
    end
end

function addrffspscenario(model::Model)
    rffspscenario = add_comp!(model, RFFSPScenario)

    rffspscenario[:model] = model
    rffspscenario[:rffsp_draw] = 0

    rffspscenario
end
