#!/bin/bash

for jj_scen in {1..4}
do
    echo $jj_scen
    nohup nice ~/added/julia-1.6.1/bin/julia runmodel_annualGrowth.jl $jj_scen &
    sleep 30
    nohup nice ~/added/julia-1.6.1/bin/julia runmodel_annualGrowth_ARvariability.jl $jj_scen &
    sleep 30
done
