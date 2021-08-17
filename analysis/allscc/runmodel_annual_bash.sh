#!/bin/bash

for jj_scen in {1..4}
do
    echo $jj_scen
    nohup nice ~/added/julia-1.6.1/bin/julia runmodel_annualGrowth.jl $jj_scen >& log1-$jj_scen.log &
    sleep 30
    nohup nice ~/added/julia-1.6.1/bin/julia runmodel_annualGrowth_ARvariability.jl $jj_scen >& log2-$jj_scen.log &
    sleep 30
done
