

@defcomp SulphateForcing begin
    region = Index()

    se0_sulphateemissionsbase = Parameter(index=[region], unit="TgS/year")
    pse_sulphatevsbase = Parameter(index=[time, region], unit="%")
    se_sulphateemissions = Variable(index=[time, region], unit="TgS/year")
    area = Parameter(index=[region], unit="km^2")
    area_e_eartharea = Parameter(unit="km2", default=5.1e8)

    sfx_sulphateflux = Variable(index=[time, region], unit="TgS/km^2/yr")

    d_sulphateforcingbase = Parameter(unit="W/m2", default=-0.46666666666666673)
    ind_slopeSEforcing_indirect = Parameter(unit="W/m2", default=-0.2333333333333333)
    nf_naturalsfx = Parameter(index=[region], unit="TgS/km^2/yr")

    fsd_directsf = Variable(index=[time, region], unit="W/m2")
    fsi_indirectsf = Variable(index=[time, region], unit="W/m2")
    fs_sulphateforcing = Variable(index=[time, region], unit="W/m2")

    function run_timestep(p, v, d, tt)
    bigSFX0 = p.se0_sulphateemissionsbase ./ p.area

    for rr in d.region
        v.se_sulphateemissions[tt, rr] = p.se0_sulphateemissionsbase[rr] * p.pse_sulphatevsbase[tt, rr] / 100

            # Eq.17 from Hope (2006) - sulfate flux
        v.sfx_sulphateflux[tt,rr] = v.se_sulphateemissions[tt,rr] / p.area[rr]
            # Update for Eq. 18 from Hope (2009) - sulfate radiative forcing effect
        bigSFD0 = p.d_sulphateforcingbase * bigSFX0[rr] / (sum(bigSFX0 .* p.area) / p.area_e_eartharea)
        v.fsd_directsf[tt, rr] = bigSFD0 * v.sfx_sulphateflux[tt,rr] / bigSFX0[rr]
        v.fsi_indirectsf[tt, rr] = p.ind_slopeSEforcing_indirect / log(2) * log((p.nf_naturalsfx[rr] + v.sfx_sulphateflux[tt, rr]) / p.nf_naturalsfx[rr])

        v.fs_sulphateforcing[tt, rr] = v.fsd_directsf[tt, rr] + v.fsi_indirectsf[tt, rr]
    end
end
end
