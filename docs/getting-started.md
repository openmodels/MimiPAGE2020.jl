# Getting Started

This guide will briefly explain how to install Julia and MimiPAGE2020.

## Installing Julia

MimiPAGE2020 requires the programming
language [Julia](http://julialang.org/), version 1.1 or later, to
run. Download and install the current release from the Julia [download page](http://julialang.org/downloads/).

## Installing Mimi

The MimiPAGE2020 model is written for the Mimi modeling framework, which needs to be installed as a standard Julia package.

Once Julia is installed, start Julia and you should see a Julia command prompt. To install the Mimi package, issue the following command:
```julia
julia> using Pkg
julia> Pkg.add("Mimi")
```

Or, alternatively enter the (Pkg REPL-mode)[https://docs.julialang.org/en/v1/stdlib/Pkg/index.html] is from the Julia REPL using the key `]`.  After typing this, you may proceed with `Pkg` methods without using `Pkg.`.  This would look like:
```julia
julia> ]add Mimi
```

To exit the Pkg REPL-mode, simply backspace once to re-enter the Julia REPL.

You only have to run this (whichever method you choose) once on your machine.

MimiPAGE2020 also requires the Distributions, DataFrames, CSVFiles, Query, and Missings packages.

For more information about the Mimi component framework, you can refer to the [Mimi](https://www.mimiframework.org/) site, which has a documentation and links to various models that are based on Mimi.

## Installing MimiPAGE2020

There are two primary ways to install and use MimiPAGE2020, and the preferred method will depend on the intended use cases. You can use it as a package or as a repository. Install it as a repository if you plan to modify the code.

### Option 1: Installing MimiPAGE2020 as a repository

Clone or download the MimiPAGE2020 repository from the
MimiPAGE2020 [Github website](https://github.com/openmodels/MimiPAGE2020).

To load MimiPAGE2020, you can `include` the `main_model.jl` file, like
so:
```
using Mimi
include("src/main_model.jl")

m = getpage()
run(m)
explore(m)
```

### Option 2: Installing MimiPAGE2020 as a package

Add the MimiPAGE2020 as a package using the following command at the julia package REPL:

```julia
pkg> add https://github.com/openmodels/MimiPAGE2020.jl.git
```

## Loading MimiPAGE2020

How you load and use the model depends on how you installed it. The key difference is how you load the model. Below is shown how to run the deterministic version of MimiPAGE2020 with central parameter estimates. The `getpage()` function creates the initialized PAGE model.

## Option 1: When MimiPAGE2020 is installed as a repository

If you have installed MimiPAGE2020 as a repository (Option 1 above), then load the model by including the `main_model.jl` and running `getpage()`, as follows:
```
using Mimi
include("src/main_model.jl")

m = getpage()
```

## Option 2: When MimiPAGE2020 is installed as a package

If you installed MimiPAGE2020 as a package, you will use the package-based syntax, as follows:
```
using MimiPAGE2020

m = MimiPAGE2020.getpage()
```

## Basic usage

Once you have a model object (`m` from above), you can print the model, by typing `m`, which returns a list of components and each of their incoming parameters and outgoing variables.

The first thing you will want to do is run the model. Do this with
```
run(m)
```

Results can be viewed by running `m[:ComponentName, :VariableName]`  for the desired component and variable. You may also explore the results graphically by running `explore(m)` to view all variables and parameters, or `explore(m, :VariableName)` for just one.

For more details on the graphical interface of Mimi look to the documentation in the Mimi [User Guide](https://www.mimiframework.org/Mimi.jl/stable/userguide/) under Plotting and the Explorer UI.

To run the stochastic version of MimiPAGE2020, which uses parameter distributions, see the `mcs.jl` file in the src folder and the documentation for Mimi Monte Carlo support [here](https://github.com/mimiframework/Mimi.jl/blob/master/docs/src/internals/montecarlo.md). The simplest version of the stochastic can be implemented as follows:
```julia
julia> do_monte_carlo_runs(1000) # 1000 runs
```
The current Monte Carlo process outputs a selection of variables that are important for validation, but these can be modified by the user if desired. For more information, see the [Technical Guide](technicaluserguide.md).

## Troubleshooting

To troubleshoot individual components, you can refer to the `test` directory, which has separate files that check each component.

For specific questions, you can send an email to [James Rising](http://existencia.org/pro) (<j.a.rising@lse.ac.uk>).

