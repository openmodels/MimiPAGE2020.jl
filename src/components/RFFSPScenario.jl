using Arrow

include("../utils/country_tools.jl")

@defcomp RFFSPScenario begin
    country = Index()

    model = Parameter{Model}()
    rffsp_draw = Parameter{Int64}()
    y_year = Parameter(index=[time], unit="year")
    y_year_0 = Parameter(unit="year")

    # Scenario values
    gpcgrw_gdppcgrowthrate = Variable(index=[time, country], unit="%/year")
    popgrw_populationgrowth = Variable(index=[time, country], unit="%/year")
    grw_gdpgrowthrate = Variable(index=[time, country], unit="%/year")

    # Input RCP values
    grw_gdpgrowthrate_rcp = Parameter(index=[time, country], unit="%/year")
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
            df = Arrow.Table(datapath("data/rffsp/grows-mean.feather")) |> DataFrame
        else
            df = Arrow.Table(datapath("data/rffsp/grows-$(((pp.rffsp_draw-1) ÷ 1000)+1).feather")) |> DataFrame
            df = df[df.num .== pp.rffsp_draw, :]
        end

        vv.popgrw_populationgrowth[:, :] = readcountrydata_it_const(pp.model, df, :ISO, :period, "pop.grow")
        vv.gpcgrw_gdppcgrowthrate[:, :] = readcountrydata_it_const(pp.model, df, :ISO, :period, "gdppc.grow")
    end

    function run_timestep(pp, vv, dd, tt)
        vv.grw_gdpgrowthrate[tt, :] = vv.popgrw_populationgrowth[tt, :] .* vv.gpcgrw_gdppcgrowthrate[tt, :]

        ## Emit = Emit_SSP * (GDP_RFF / GDP_SSP)
        ## grow Emit = grow Emit_SSP + grow GDP_RFF - grow GDP_SSP
        adjust = countrytoregion(pp.model, vv -> mean(filter(!isnan, vv)), vv.grw_gdpgrowthrate[tt, :] - pp.grw_gdpgrowthrate_rcp[tt, :])

        for rr in dd.region
            if is_first(tt)
                prev_erco2 = 100.
                prev_erch4 = 100.
                prev_ern2o = 100.
                prev_erlg = 100.
                prev_pse = 100.
                deltat = pp.y_year[tt] - pp.y_year_0
            else
                prev_erco2 = pp.er_CO2emissionsgrowth_rcp[tt-1, rr]
                prev_erch4 = pp.er_CH4emissionsgrowth_rcp[tt-1, rr]
                prev_ern2o = pp.er_N2Oemissionsgrowth_rcp[tt-1, rr]
                prev_erlg = pp.er_LGemissionsgrowth_rcp[tt-1, rr]
                prev_pse = pp.pse_sulphatevsbase_rcp[tt-1, rr]
                deltat = pp.y_year[tt] - pp.y_year[tt-1]
            end

            if prev_erco2 == 0
                vv.er_CO2emissionsgrowth[tt, rr] = 0
            else
                er_CO2emissionsgrowth_rate = log.(pp.er_CO2emissionsgrowth_rcp[tt, rr] ./ prev_erco2) / deltat + adjust[rr]
                vv.er_CO2emissionsgrowth[tt, rr] = prev_erco2 * exp.(er_CO2emissionsgrowth_rate * deltat)
            end

            if prev_erch4 == 0
                vv.er_CH4emissionsgrowth[tt, rr] = 0
            else
                er_CH4emissionsgrowth_rate = log.(pp.er_CH4emissionsgrowth_rcp[tt, rr] ./ prev_erch4) / deltat + adjust[rr]
                vv.er_CH4emissionsgrowth[tt, rr] = prev_erch4 * exp.(er_CH4emissionsgrowth_rate * deltat)
            end

            if prev_ern2o == 0
                vv.er_N2Oemissionsgrowth[tt, rr] = 0
            else
                er_N2Oemissionsgrowth_rate = log.(pp.er_N2Oemissionsgrowth_rcp[tt, rr] ./ prev_ern2o) / deltat + adjust[rr]
                vv.er_N2Oemissionsgrowth[tt, rr] = prev_ern2o * exp.(er_N2Oemissionsgrowth_rate * deltat)
            end

            if prev_erlg == 0
                vv.er_LGemissionsgrowth[tt, rr] = 0
            else
                er_LGemissionsgrowth_rate = log.(pp.er_LGemissionsgrowth_rcp[tt, rr] ./ prev_erlg) / deltat + adjust[rr]
                vv.er_LGemissionsgrowth[tt, rr] = prev_erlg * exp.(er_LGemissionsgrowth_rate * deltat)
            end

            if prev_pse == 0
                vv.pse_sulphatevsbase[tt, rr] = 0
            else
                pse_sulphatevsbase_rate = log.(pp.pse_sulphatevsbase_rcp[tt, rr] ./ prev_pse) / deltat + adjust[rr]
                vv.pse_sulphatevsbase[tt, rr] = prev_erco2 * exp.(pse_sulphatevsbase_rate * deltat)
            end
        end
    end
end

function addrffspscenario(model::Model)
    rffspscenario = add_comp!(model, RFFSPScenario)

    rffspscenario[:model] = model
    rffspscenario[:rffsp_draw] = 0
    rffspscenario[:y_year] = Mimi.dim_keys(model.md, :time)

    rffspscenario
end
