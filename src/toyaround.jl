impf_coeffbayesmultivar_EU = MvNormal([0.016778919178202237, -6.589588822829189e-4],
                                      [8.37310821714339E-08  -3.23802901733813E-09;
                                      -3.23802901733813E-09 1.25609945404031E-10])

#
impf_coeffbayesmultivar_EU_draw = rand(impf_coeffbayesmultivar_EU)

Random.seed!(1)
impf_coeffbayesmultivar_EU_draw = rand(MvNormal([0.016778919178202237, -6.589588822829189e-4],
                                      [8.37310821714339E-08  -3.23802901733813E-09;
                                      -3.23802901733813E-09 1.25609945404031E-10]))[2]


impf_coefflinearregion_bayes = DataFrame(EU = -999)
impf_coefflinearregion_bayes["EU"] = impf_coeffbayesmultivar_EU_draw[1]

m = getpage()
run(m)

reset_masterparameters()
Random.seed!(1)
temp = get_scc_mcs(10000, 2020, string(dir_output, "montecarlo/testmultivariate/"))
mean(temp[:,1])
Statistics.std(temp[:,1])
global modelspec_master = "PAGE09"
Random.seed!(1)
temp2 = get_scc_mcs(10000, 2020, string(dir_output, "montecarlo/testmultivariatePAGE09/"))
mean(temp2[:,1])
Statistics.std(temp2[:,1])
writedlm(string(dir_output, "montecarlo/testmultivariatePAGE09/SCC-PAGE09.csv"),
                        temp2, ",")

reset_masterparameters()
global modelspec_master = "Burke"
Random.seed!(1)
temp3 = get_scc_mcs(10000, 2020, string(dir_output, "montecarlo/testmultivariateBURKE/"))
writedlm(string(dir_output, "montecarlo/testmultivariateBurke/SCC-Burke.csv"),
                        temp2, ",")
mean(temp3[:,1])
Statistics.std(temp3[:,1])
