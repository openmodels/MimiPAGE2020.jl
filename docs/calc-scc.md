# Calculating the Social Cost of Carbon

Here is an example of computing the social cost of carbon with MimiPAGE2020. Note that the units of the returned value are dollars $/ton CO2.

The example below is written for when MimiPAGE2020 is installed as a package. The corresponding code for computing the SCC when installed as a repository is to `include("src/compute_scc.jl")` and then to run the functions below without the `MimiPAGE2020.` prefix.

This example computes the SCC in 2020:
```
using Mimi
using MimiPAGE2020

# Get the social cost of carbon in year 2020 from the default MimiPAGE2020 model:
scc = MimiPAGE2020.compute_scc(year = 2020)

# You can also compute the SCC from a modified version of a MimiPAGE2020 model:
m = MimiPAGE2020.get_model()    # Get the default version of the MimiPAGE2020 model
set_param!(m, :tcr_transientresponse, 3)    # Try a higher transient climate response value
scc = MimiPAGE2020.compute_scc(m, year=2020)    # compute the scc from the modified model by passing it as the first argument to compute_scc
```
The first argument to the `compute_scc` function is a MimiPAGE2020 model, and it is an optional argument. If no model is provided, the default MimiPAGE2020 model will be used. 

There are also other keyword arguments available to `compute_scc`. Note that the user must specify a `year` for the SCC calculation, but the rest of the keyword arguments have default values.

Note that a pulse "in 2020" produces a gradual increase from 2015-2020 (or whatever the preceeding period is), followed by a gradual decrease in emissions from 2020-2030 (or whatever that following period is). Emissions are linearly interpolated between the points given by the years.
```
compute_scc(
    m = get_model(),  # if no model provided, will use the default MimiPAGE2020 model
    year = nothing,  # user must specify an emission year for the SCC calculation
    eta = nothing,  # eta parameter for ramsey discounting representing the elasticity of marginal utility. If nothing is provided, the value of parameter :emuc_utiliyconvexity in the MimiPAGE2020 model is unchanged, which has a default value of 1.1666666667.
    prtp = nothing,  # pure rate of time preference parameter used for discounting. If nothing is provided, the value of parameter :ptp_timepreference in the MimiPAGE2020 model is unchanged, which has a default value of 1.0333333333%.
    equity_weighting  = true,
    pulse_size = 100_000 # the pulse size in metric megatonnes of CO2 (Mtonne CO2) (see below for more details)
)
```
There is an additional function for computing the SCC that also returns the MarginalModel that was used to compute it. It returns these two values as a NamedTuple of the form (scc=scc, mm=mm). The same keyword arguments from the `compute_scc` function are available for the `compute_scc_mm` function. Example:
```
using Mimi
using MimiPAGE2020

result = MimiPAGE2020.compute_scc_mm(year=2030, eta=0, prtp=0.025)

result.scc  # returns the computed SCC value

result.mm   # returns the Mimi MarginalModel

marginal_temp = result.mm[:ClimateTemperature, :rt_realizedtemperature]  # marginal results from the marginal model can be accessed like this
```

### Pulse Size Details

By default, MimiPAGE2020 will calculate the SCC using a marginal emissions pulse of 100_000 metric megatonnes of CO2 (Mtonne CO2) spread over the years before and after `year`.  Regardless of this pulse size, the SCC will be returned in units of dollars per ton since it is normalized over this pulse size.  This choice of pulse size and duration is a decision made based on experiments with stability of results and moving from continuous to discretized equations, and can be found described further in the literature around PAGE.

If you wish to alter this pulse size, it is an optional keyword argument to the  `compute_scc` function where `pulse_size` controls the size of the marginal emission pulse. For a deeper dive into the machinery of this function, see the forum conversation [here](https://forum.mimiframework.org/t/mimifund-emissions-pulse/153/9) and the docstrings in `compute_scc.jl`.
