@defcomp AdaptationCostsSeaLevel begin
    country = Index()

    s_sealevel = Parameter(index=[time], unit="m")

    alpha_noadapt = Parameter(index=[country])
    beta_noadapt = Parameter(index=[country])
    alpha_optimal = Parameter(index=[country])
    beta_optimal = Parameter(index=[country])
    saf_slradaptfrac = Parameter(index=[time, country])

    ac_adaptivecosts = Variable(index=[time, country], unit="\$million")

    function run_timestep(p, v, d, tt)

        slrmm = p.s_sealevel * 1000
        adaptcost_noadapt = p.alpha_noadapt * slrmm + p.beta_noadapt * slrmm^2
        adaptcost_optimal = p.alpha_optimal * slrmm + p.beta_optimal * slrmm^2

        v.ac_adaptivecosts[tt, :] = adaptcost_noadapt * (1 - p.saf_slradaptfrac) + adaptcost_optimal * p.saf_slradaptfrac
    end
end

function addadaptationcosts_sealevel(model::Model)
    adaptationcosts = add_comp!(model, AdaptationCostsSeaLevel)

    adaptationcosts[:alpha_noadapt] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "alpha.adapts.noadapt", values -> 0.)
    adaptationcosts[:beta_noadapt] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "beta.adapts.noadapt", values -> 0.)
    adaptationcosts[:alpha_optimal] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "alpha.adapts.optimal", values -> 0.)
    adaptationcosts[:beta_optimal] = readcountrydata_im(model, "damages/slremul.csv", :adm0, :bs, nothing, "beta.adapts.optimal", values -> 0.)
    adaptationcosts[:saf_slradaptfrac] = Matrix(0.5, dim_count(model, :time), dim_count(model, :country))

    return adaptationcosts
end
