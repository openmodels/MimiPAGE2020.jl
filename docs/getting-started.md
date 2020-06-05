# Getting Started

This guide will briefly explain how to install Julia and PAGE-2020.

## Installing Julia

PAGE-2020 requires the programming
language [Julia](http://julialang.org/), version 1.1 or later, to
run. Download and install the current release from the Julia [download page](http://julialang.org/downloads/).

### Julia Editor Support

There are various editors around that have Julia support:

- [IJulia](https://github.com/JuliaLang/IJulia.jl) adds Julia support to the [jupyter](http://jupyter.org/) (formerly IPython) notebook system.
- [Juno](http://junolab.org/) adds Julia specific features to the [Atom](https://atom.io/) editor.
- [Sublime](https://www.sublimetext.com/), [VS Code](https://code.visualstudio.com/), [Emacs](https://www.gnu.org/software/emacs/) and many other editors all have Julia extensions that add various levels of support for the Julia language.

## Installing Mimi

The PAGE-2020 model is written for the Mimi modeling framework, which
needs to be installed as a standard Julia package.

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

PAGE-2020 also requires the Distributions, DataFrames, CSVFiles, Query, and Missings packages.

For more information about the Mimi component framework, you can refer to the [Mimi](https://www.mimiframework.org/) site, which has a documentation and links to various models that are based on Mimi.

## Installing PAGE-2020

Clone or download the PAGE-2020 repository from the PAGE-2020 [Github website](https://github.com/openmodels/mimi-page-2020.jl).

## Using PAGE-2020

To run the model, run the `main.jl` file in the examples folder. This
runs the deterministic version of PAGE-2020 with central parameter
estimates. The `main_model.getpage` function used in that file creates the
initialized PAGE model. You can print the model, by typing `m`, which
returns a list of components and each of their incoming parameters and
outgoing variables. Results can be viewed by running `m[:ComponentName, :VariableName]` 
for the desired component and variable. You may also explore the results graphically
by running `explore(m)` to view all variables and parameters, or `explore(m, :VariableName)`
for just one. For more details on the graphical interface of Mimi look to the
documentation in the
Mimi
[User Guide](https://www.mimiframework.org/Mimi.jl/stable/userguide/) under
Plotting and the Explorer UI.

For more details on the graphical interface of Mimi look to the
documentation in the
Mimi
[User Guide](https://www.mimiframework.org/Mimi.jl/stable/userguide/)
under Plotting and the Explorer UI.

To run the stochastic version of PAGE-2020, which uses parameter
distributions, see the `mcs.jl` file in the src folder and the documentation for
Mimi Monte Carlo support [here](https://github.com/mimiframework/Mimi.jl/blob/master/docs/src/internals/montecarlo.md). The simplest version of the stochastic can be implemented as follows:
```julia
julia> do_monte_carlo_runs(1000) # 1000 runs
```
The current Monte Carlo process outputs a selection of variables that are
important for validation, but these can be modified by the user if
desired. For more information, see the [Technical Guide](technicaluserguide.md).

## Troubleshooting

To troubleshoot individual components, you can refer to the `test` directory, which has separate files that check each component.

For specific questions, you can send an email to [James Rising](http://existencia.org/pro) (<j.a.rising@lse.ac.uk>).
