# PAGE-2020 - Open-Source Repository for the PAGE-2020 Integrated Assessment Model

![](https://github.com/openmodels/MimiPAGE2020.jl/workflows/Run%20CI%20on%20master/badge.svg)

PAGE-2020 (Policy Analysis of Greenhouse Effect, v. 2020) is a
cost-benefit Integrated Assessment Model. It builds upon
the [PAGE-ICE model](https://github.com/openmodels/PAGE-ICE/),
developed by
[Yumashev et al. (2019)](https://www.nature.com/articles/s41467-019-09863-x#Sec14).

The most up-to-date publication for the PAGE-2020 model is Jarmo et
al. (2021). The social cost of carbon dioxide under climate-economy
feedbacks and temperature variability. ERL.
https://iopscience.iop.org/article/10.1088/1748-9326/ac1d0b

Reproduction data and scripts for that paper are available at
https://zenodo.org/record/5417548.

The main advancements for the PAGE-2020 are:
 - Extended and corrected SSP data
 - Improved market damages, based on Burke et al. (2015).
 - Partial growth feedbacks
 - Optional annual timesteps and variability

## Getting started

For software requirements, installation instructions, and basic usage,
see the [Getting started](https://github.com/openmodels/PAGE-2020/tree/master/docs/getting-started.md) page.

Information on computing an SCC in PAGE-2020 is available in
the [Calculating the Social Cost of Carbon](https://github.com/openmodels/PAGE-2020/tree/master/docs/calc-scc.md) page.

## Running the Model

It is highly recommended to read the Mimi documentation first to
understand the code structure. For starter code on running the model
just once, see the code in the file `examples/main.jl`.

In order to create a reproducible environment, you can move into the main
directory of this repository, do
```julia
pkg> activate .
(MimiPAGE2020) pkg> instantiate
(MimiPAGE2020) pkg> up
```
which should first install the correct package dependencies, and
then `up` forces compatibility.

Running the model can be done in several ways, for instance from the root of the directory by doing:
```julia
julia> include("src/runpage.jl")
```

## More documentation

More documentation is available under the [docs](https://github.com/openmodels/PAGE-2020/tree/master/docs) directory.
