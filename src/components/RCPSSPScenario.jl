@defcomp RCPSSPScenario begin
    region = Index()

    rcp::String = Parameter() # like rcp26
    ssp::String = Parameter() # like ssp1

    # RCP scenario values
    er_CO2emissionsgrowth = Variable(index=[time,region], unit="%")
    er_CH4emissionsgrowth = Variable(index=[time,region], unit="%")
    er_N2Oemissionsgrowth = Variable(index=[time,region], unit="%")
    er_LGemissionsgrowth = Variable(index=[time,region], unit="%")
    pse_sulphatevsbase = Variable(index=[time, region], unit="%")
    exf_excessforcing = Variable(index=[time], unit="W/m2")

    # SSP scenario values
    popgrw_populationgrowth = Variable(index=[time, region], unit="%/year") # From p.32 of Hope 2009
    grw_gdpgrowthrate = Variable(index=[time, region], unit="%/year") #From p.32 of Hope 2009

    function init(p, v, d)
        # Set the RCP values
        v.er_CO2emissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_co2.csv")
        v.er_CH4emissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_ch4.csv")
        v.er_N2Oemissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_n2o.csv")
        v.er_LGemissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_lin.csv")
        v.pse_sulphatevsbase = readpagedata(nothing, "data/rcps/$(rcp)_sulph.csv")
        v.exf_excessforcing = readpagedata(nothing, "data/rcps/$(rcp)_excess.csv")

        # Set the SSP values
        v.grw_gdpgrowthrate = readpagedata(nothing, "data/ssps/$(ssp)_pop_rate.csv")
        v.popgrw_populationgrowth = readpagedata(nothing, "data/ssps/$(ssp)_gdp_rate.csv")
    end
end
