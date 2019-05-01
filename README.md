# PAGE-ICE - Open-Source Repository for the PAGE-ICE Integrated Assessment Model

[![](https://img.shields.io/badge/docs-stable-blue.svg)](http://anthofflab.berkeley.edu/mimi-page-2020.jl/stable/)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](http://anthofflab.berkeley.edu/mimi-page-2020.jl/latest/)
[![Build Status](https://travis-ci.org/anthofflab/mimi-page-2020.jl.svg?branch=master)](https://travis-ci.org/anthofflab/mimi-page-2020.jl)
[![codecov](https://codecov.io/gh/anthofflab/mimi-page-2020.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/anthofflab/mimi-page-2020.jl)

PAGE-ICE (Policy Analysis of Greenhouse Effect - Ice, Climate,
Economics) is a cost-benefit Integrated Assessment Model.  
This repository contains two versions of the PAGE-ICE, implemented in
Excel using @RISK and in Julia using Mimi.

The PAGE-ICE model is introduced
in
[Yumashev et al. (2019)](https://www.nature.com/articles/s41467-019-09863-x#Sec14).
It extends PAGE09
([Hope, 2011](https://www.jbs.cam.ac.uk/fileadmin/user_upload/research/workingpapers/wp1104.pdf),
[Hope 2006](http://78.47.223.121:8080/index.php/iaj/article/view/227))
with nonlinear arctic feedbacks, empirical market damages, IPCC
scenarios, and other changes.  See
the
[technical documentation](https://github.com/openmodels/PAGE-ICE/blob/master/PAGE-ICE%20v6.22%20Technical%20Description%20-%20v%2024%20Apr%202019.pdf?raw=true) for
more information.

The original version of PAGE-ICE is written in Excel, like the
previous versions of PAGE.  The Excel version of PAGE-ICE requires
the [@RISK](https://www.palisade.com/risk/) Monte Carlo system.  You
can download
the
[Excel version](https://github.com/openmodels/PAGE-ICE/blob/master/PAGE-ICE%20v6.22%20Nonlinear%20Arctic%20Feedbacks%20-%20Default.xlsx?raw=true),
which features a Cockpit for setting up the model and a Results tab
for the main result.

The model has also been ported to the [Julia](https://julialang.org)
programming language, using
the [Mimi framework](https://www.mimiframework.org/).  The Mimi
version of PAGE-ICE is based on Mimi-PAGE-2009
([Moore et al., 2018](https://www.nature.com/articles/sdata2018187)).
The documentation for Mimi-PAGE-2020.jl can be
accessed
[here](http://anthofflab.berkeley.edu/MimiPAGE2009.jl/stable/), and
the code is available in this repository.  More
details on downloading and running the Mimi version of the model are
available below.

## Mimi Software Requirements

You need to install [julia 1.1](https://julialang.org) or newer to run
this model.

You probably also want to install the Mimi package into your julia environment,
so that you can use some of the tools in there:

```julia
pkg> add Mimi
```

## Running the Mimi Model
The model uses the Mimi framework and it is highly recommended to read the Mimi documentation first to understand the code structure. For starter code on running the model just once, see the code in the file `examples/main.jl`.

