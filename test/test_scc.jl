using Test
using Mimi

function checksccs(sccs, sccomp)
    sccobs = [quantile(sccs, [.05, .25, .5, .75, .95]); mean(sccs)]
    sccerror = abs.((sccobs - scccomp) ./ [10, 1, 1, 1, 10, 1])
    sccsd = std(sccs) / sqrt(1000)
    @test all(sccerror .< 3*sccsd) # average off by < 3x SD
end

m = getpage("RCP4.5 & SSP2", true, true, true)
sccs = compute_scc_mcs(m, 1000, year=2020)
checksccs(sccs, [37.031, 89.742, 161.868, 299.439, 847.020, 261.739])

# m = getpage("RCP8.5 & SSP5", true, true, true)
# sccs = compute_scc_mcs(m, 1000, year=2020)

m = getpage("RCP4.5 & SSP2", true, true, false)
sccs = compute_scc_mcs(m, 1000, year=2020)
checksccs(sccs, [53.903, 129.330, 217.337, 361.739, 886.998, 306.914])

# m = getpage("RCP8.5 & SSP5", true, true, false)
# sccs = compute_scc_mcs(m, 1000, year=2020)

end
