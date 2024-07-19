using GLM
using Statistics
using DataFrames
using CSV
using ExcelFiles
using RCall

include("main_model.jl")

model = getpage(use_rffsp=true)
run(model)

rcons = getdataframe(model, :Discontinuity, :rcons_per_cap_DiscRemainConsumption)

discounting = 0.03
times = unique(rcons.time)
timediff = [5; diff(times)]

result = DataFrame(iso=unique(rcons.country))
result[!, :npv_consutil] = [sum(timediff .* exp.(-discounting * (times .- 2020)) .* log.(rcons.rcons_per_cap_DiscRemainConsumption[rcons.country .== iso])) for iso in result.iso]

function get_capital(filepath)
    df = CSV.read(filepath, DataFrame)

    df.Country[df.Country .== "Bolivia (Plurinational State of)"] .= "Bolivia"
    df.Country[df.Country .== "Congo"] .= "Congo, Rep."
    df.Country[df.Country .== "Côte d’Ivoire"] .= "Cote d'Ivoire"
    df.Country[df.Country .== "Czech Republic"] .= "Czechia"
    df.Country[df.Country .== "Democratic Republic of the Congo"] .= "Congo, Dem. Rep."
    df.Country[df.Country .== "Egypt"] .= "Egypt, Arab Rep."
    df.Country[df.Country .== "Gambia"] .= "Gambia, The"
    df.Country[df.Country .== "Iran (Islamic Republic of)"] .= "Iran, Islamic Rep."
    df.Country[df.Country .== "Kyrgyzstan"] .= "Kyrgyz Republic"
    df.Country[df.Country .== "Lao People’s Democratic Republic"] .= "Lao PDR"
    df.Country[df.Country .== "Republic of Korea"] .= "Korea, Rep."
    df.Country[df.Country .== "Republic of Moldova"] .= "Moldova"
    df.Country[df.Country .== "Slovakia"] .= "Slovak Republic"
    df.Country[df.Country .== "Sudan (former)"] .= "Sudan"
    df.Country[df.Country .== "Swaziland"] .= "Eswatini"
    df.Country[df.Country .== "Turkey"] .= "Turkiye"
    df.Country[df.Country .== "United Republic of Tanzania"] .= "Tanzania"
    df.Country[df.Country .== "United States of America"] .= "United States"
    df.Country[df.Country .== "Venezuela (Bolivarian Republic of)"] .= "Venezuela, RB"
    df.Country[df.Country .== "Viet Nam"] .= "Vietnam"
    df.Country[df.Country .== "Yemen"] .= "Yemen, Rep."

    df
end

a1 = get_capital("/Users/admin/Library/CloudStorage/GoogleDrive-jrising@udel.edu/My Drive/Research/Current Losses/data/capital/tabula-A1-nonrenewable.csv")
a2 = get_capital("/Users/admin/Library/CloudStorage/GoogleDrive-jrising@udel.edu/My Drive/Research/Current Losses/data/capital/tabula-A2-renewable.csv")
bb = get_capital("/Users/admin/Library/CloudStorage/GoogleDrive-jrising@udel.edu/My Drive/Research/Current Losses/data/capital/tabula-B-human.csv")
cc = get_capital("/Users/admin/Library/CloudStorage/GoogleDrive-jrising@udel.edu/My Drive/Research/Current Losses/data/capital/tabula-C-produced.csv")
xf = DataFrame(load("/Users/admin/Library/CloudStorage/GoogleDrive-jrising@udel.edu/My Drive/Research/Current Losses/data/capital/API_SP.POP.TOTL_DS2_en_excel_v2_5871620.xls", "Data", skipstartrows=3))

function add_xf(df)
    dfxf = leftjoin(df, xf, on=:Country => Symbol("Country Name"), renamecols="_cap" => "_pop")
    dfxf[ismissing.(dfxf."Country Code_pop"), :Country]

    dfxf[!, "1990"] .= dfxf."1990_cap" ./ dfxf."1990_pop"
    dfxf[!, "1995"] .= dfxf."1995_cap" ./ dfxf."1995_pop"
    dfxf[!, "2000"] .= dfxf."2000_cap" ./ dfxf."2000_pop"
    dfxf[!, "2005"] .= dfxf."2005_cap" ./ dfxf."2005_pop"
    dfxf[!, "2010"] .= dfxf."2010_cap" ./ dfxf."2010_pop"
    dfxf[!, "2014"] .= dfxf."2014_cap" ./ dfxf."2014_pop"

    dfxf
end

bbxf = add_xf(bb)
ccxf = add_xf(cc)

function extrap2100(row)
    xxs = [1990, 1995, 2000, 2005, 2010, 2014]
    yyvals = [row["1990"], row["1995"], row["2000"], row["2005"], row["2010"], row["2014"]]
    keep = (yyvals .!= "NA") .& (yyvals .!= "0")
    if sum(keep) == 0
        return missing
    end
    yys = log.(parse.(Float64, yyvals[keep]))

    mod = lm(@formula(yys ~ xxs), DataFrame(xxs=xxs[keep], yys=yys))
    corr = var(predict(mod, DataFrame(xxs=xxs[keep])) .- yys) / 2
    return exp(predict(mod, DataFrame(xxs=2100))[1] + corr)
end

function extrap2100_num(row)
    xxs = [1990, 1995, 2000, 2005, 2010, 2014]
    yys = log.([row["1990"], row["1995"], row["2000"], row["2005"], row["2010"], row["2014"]])

    mod = lm(@formula(yys ~ xxs), DataFrame(xxs=xxs, yys=yys))
    corr = var(predict(mod, DataFrame(xxs=xxs)) .- yys) / 2
    return exp(predict(mod, DataFrame(xxs=2100))[1] + corr)
end

function npv_num(row)
    println(row.Country)
    xxs = [1990, 1995, 2000, 2005, 2010, 2014]
    yys = log.([row["1990"], row["1995"], row["2000"], row["2005"], row["2010"], row["2014"]])

    mod = lm(@formula(yys ~ xxs), DataFrame(xxs=xxs, yys=yys))
    corr = var(predict(mod, DataFrame(xxs=xxs)) .- yys) / 2
    vals = exp(predict(mod, DataFrame(xxs=2026:2100))[1] + corr)
    sum(vals .* exp.(-.03 * (0:75)))
end

function frac2100(row)
    in2100 = extrap2100(row)
    maxnow = maximum(exp.(yys))

    return min(in2100 / maxnow, 1)
end

function frac2100_num(row)
    in2100 = extrap2100_num(row)
    maxnow = maximum(exp.(yys))

    return min(in2100 / maxnow, 1)
end

a1[!, :frac2100] = [frac2100(row) for row in eachrow(a1)]
a2[!, :frac2100] = [frac2100_num(row) for row in eachrow(a2)]
bbxf[!, :npv2100] = [npv_num(row) for row in eachrow(bbxf)]
ccxf[!, :npv2100] = [npv_num(row) for row in eachrow(ccxf)]

gini = DataFrame(load("/Users/admin/projects/strategy/API_SI.POV.GINI_DS2_en_excel_v2_476423.xls", "Data", skipstartrows=3))
gini[!, :latest] = [(row |> collect)[.!ismissing.(row |> collect)][end] for row in eachrow(gini)]
gini.latest[gini.latest .== "SI.POV.GINI"] .= missing

life = DataFrame(load("/Users/admin/projects/strategy/API_SP.DYN.LE00.IN_DS2_en_excel_v2_497356.xls", "Data", skipstartrows=3))
life[!, :latest] = [(row |> collect)[.!ismissing.(row |> collect)][end] for row in eachrow(life)]
life.latest[life.latest .== "SP.DYN.LE00.IN"] .= missing

bycountry = CSV.read("../data/bycountry.csv", DataFrame)

result2 = leftjoin(
leftjoin(leftjoin(leftjoin(leftjoin(leftjoin(leftjoin(leftjoin(
    result, xf[!, ["Country Name", "Country Code"]], on=:iso => Symbol("Country Code")),
                                                      a1[!, ["Country", "frac2100"]], on=Symbol("Country Name") => :Country, renamecols="" => "_non", matchmissing=:notequal),
                                             a2[!, ["Country", "frac2100"]], on=Symbol("Country Name") => :Country, renamecols="" => "_ren", matchmissing=:notequal),
                                    bbxf[!, ["Country", "npv2100"]], on=Symbol("Country Name") => :Country, renamecols="" => "_hum", matchmissing=:notequal),
                           ccxf[!, ["Country", "npv2100"]], on=Symbol("Country Name") => :Country, renamecols="" => "_pro", matchmissing=:notequal),
                  gini[!, ["Country Code", "latest"]], on=:iso => Symbol("Country Code"), renamecols="" => "_gini", matchmissing=:notequal),
         life[!, ["Country Code", "latest"]], on=:iso => Symbol("Country Code"), renamecols="" => "_life", matchmissing=:notequal),
bycountry, on=:iso => :ISO3)
result2.latest_gini = Vector{Union{Float64, Missing}}(result2.latest_gini)
result2.latest_life = Vector{Union{Float64, Missing}}(result2.latest_life)

CSV.write("/Users/admin/projects/strategy/countries.csv", result2)

XX = result2[!, [2; 4:9; 11:ncol(result2)]]
R"""
library(mice)
impObject <- mice($(XX), method="cart")
completedData <- complete(impObject, 1)
"""
result3mice = rcopy(R"completedData")

result3alt = copy(XX)
for col in names(XX)
    values = XX[!, col]
    if values isa Vector{Float64}
        continue
    end
    values[ismissing.(values) .| isnan.(values)] .= missing
    min_val = minimum(skipmissing(XX[!, col]))
    result3alt[ismissing.(values), col] .= min_val
end

result3 = sqrt.(result3mice .* result3alt)

result3[!, :iso] = result2.iso
result3[!, "Country Name"] = result2.Country

CSV.write("/Users/admin/projects/strategy/countries.csv", result3)

