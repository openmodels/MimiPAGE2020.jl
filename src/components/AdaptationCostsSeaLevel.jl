@defcomp AdaptiveCostsSeaLevel begin
    country = Index()

    sealevelcost_draw = Parameter{Int64}()

    s_sealevel = Parameter(index=[time], unit="m")
    gdp = Parameter(index=[time, country], unit="\$M")

    alpha_noadapt = Parameter(index=[country])
    beta_noadapt = Parameter(index=[country])
    alpha_optimal = Parameter(index=[country])
    beta_optimal = Parameter(index=[country])
    saf_slradaptfrac = Parameter(index=[time, country])

    ac_adaptivecosts = Variable(index=[time, country], unit="\$million")

    function init(pp, vv, dd)
        if pp.sealevelcost_draw == -1
            vv.alpha_noadapt = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, nothing, "alpha.adapts.noadapt", values -> 0.)
            vv.beta_noadapt = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, nothing, "beta.adapts.noadapt", values -> 0.)
            vv.alpha_optimal = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, nothing, "alpha.adapts.optimal", values -> 0.)
            vv.beta_optimal = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, nothing, "beta.adapts.optimal", values -> 0.)
        else
            vv.alpha_noadapt = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, pp.sealevelcost_draw, "alpha.adapts.noadapt", values -> 0.)
            vv.beta_noadapt = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, pp.sealevelcost_draw, "beta.adapts.noadapt", values -> 0.)
            vv.alpha_optimal = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, pp.sealevelcost_draw, "alpha.adapts.optimal", values -> 0.)
            vv.beta_optimal = readcountrydata_im(model, "data/damages/slremul.csv", "adm0", :bs, pp.sealevelcost_draw, "beta.adapts.optimal", values -> 0.)
        end
    end

    function run_timestep(p, v, d, tt)
        slrmm = p.s_sealevel[tt] * 1000

        for cc in d.country
            # fraction of GDP -> $million
            adaptcost_noadapt = (p.alpha_noadapt[cc] * slrmm + p.beta_noadapt[cc] * slrmm^2) * p.gdp[tt, cc]
            adaptcost_optimal = (p.alpha_optimal[cc] * slrmm + p.beta_optimal[cc] * slrmm^2) * p.gdp[tt, cc]

            v.ac_adaptivecosts[tt, cc] = adaptcost_noadapt * (1 - p.saf_slradaptfrac[tt, cc]) + adaptcost_optimal * p.saf_slradaptfrac[tt, cc]
        end
    end
end

function addadaptationcosts_sealevel(model::Model)
    adaptationcosts = add_comp!(model, AdaptiveCostsSeaLevel)

    adaptationcosts[:sealevelcost_draw] = -1
    adaptationcosts[:saf_slradaptfrac] = 0.5 * ones(dim_count(model, :time), dim_count(model, :country))

    return adaptationcosts
end
