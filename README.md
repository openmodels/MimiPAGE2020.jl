# PAGE-2020 - Open-Source Repository for the PAGE-2020 Integrated Assessment Model

[![Build Status](https://travis-ci.com/openmodels/mimi-page-2020.jl.svg?branch=master)](https://travis-ci.com/openmodels/mimi-page-2020.jl)

PAGE-2020 (Policy Analysis of Greenhouse Effect, v. 2020) is a
cost-benefit Integrated Assessment Model. It builds upon
the [PAGE-ICE model](https://github.com/openmodels/PAGE-ICE/),
developed
by
[Yumashev et al. (2019)](https://www.nature.com/articles/s41467-019-09863-x#Sec14).

The main advancements for the PAGE-2020 are:
 - Extended and corrected SSP data
 - Improved market damages, based on Burke et al. (2015).
 - Partial growth feedbacks
 - Optional annual timesteps and variability

## Software Requirements
You need to install [julia 1.1](https://julialang.org) or newer to run this model.

The model uses the Mimi framework, and you will want to install the
Mimi package into your julia environment:

```julia
pkg> add Mimi
```

## Running the Model

Iit is highly recommended to read the Mimi documentation first to
understand the code structure. For starter code on running the model
just once, see the code in the file `examples/main.jl`.

## More documentation

More documentation is available under
the
[docs](https://github.com/openmodels/mimi-page-2020.jl/tree/master/docs) directory.
