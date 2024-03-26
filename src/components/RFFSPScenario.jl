using Arrow

include("../utils/country_tools.jl")

@defcomp RFFSPScenario begin
    country = Index()

    model = Parameter{Model}()
    rffsp_draw = Parameter{Int74}()

    # Scenario values
    gpcgrw_gdppcgrowthrate = Variable(index=[time, country], unit="%/year")
    popgrw_populationgrowth = Variable(index=[time, country], unit="%/year")
    grw_gdpgrowthrate = Variable(index=[time, country], unit="%/year")

    function init(pp, vv, dd)
        if pp.rffsp_draw == 0
            df = Arrow.Table(datapath("rffsp/grows-mean.feather")) |> DataFrame
        else
            df = Arrow.Table(datapath("rffsp/grows-{((pp.rffsp_draw-1) ÷ 1000)+1}.feather")) |> DataFrame
        end

        vv.popgrw_populationgrowth[:, :] = readcountrydata_it_const(pp.model, df, :ISO, :period, "pop.grow")
        vv.gpcgrw_populationgrowth[:, :] = readcountrydata_it_const(pp.model, df, :ISO, :period, "gdppc.grow")
    end

    function run_timestep(pp, vv, dd, tt)
        vv.grw_gdpgrowthrate[tt, :] = vv.popgrw_populationgrowth[tt, :] .* vv.gpcgrw_gdppcgrowthrate[tt, :]
    end
end

function addrffspscenario(model::Model)
    rffspscenario = add_comp!(model, RFFSPScenario)

    rffspscenario[:model] = model
    rffspscenario[:rffsp_draw] = 0

    rffspscenario
end
