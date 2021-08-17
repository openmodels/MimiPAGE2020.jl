# Understanding PAGE Timesteps

All of the main outputs of the model are intended to be representative of the particular year described in the timestep (e.g., 2020). In some cases, that requires inputs or intermediate values that represent a span of years, but with only one exception, these spans are the years between the timestep years.  The exception is for the final calculations of the SCC, where the values calculated for each timestep year are applied to the span of years centered on that year.

To make that more clear, let the timestep year be `t[i]`: so, `t[0] = 2015`, the baseline year; `t[1] = 2020`, `t[2] = 2030`, etc.. Then there are two definitions of the duration between timesteps. The 'between' duration is `t[i+1] - t[i]`, and the 'centered' duration is `(t[i+1] + t[i]) / 2 - (t[i] + t[i-1]) / 2`.

When describing the meaning of the values, I will use one of the following phrases: (1) that a variable for timestep `t[i]` describes the value "at time `t[i]`": this means, for example, that the 2030 value is mean to just represent what happens in 2030; or (2) that a variable for timestep `t[i]` describes the value as an average over a duration: here, the 2030 value might be an average over the between duration leading up to 2030 (2020 - 2030) or an average over the centered duration around 2030 (2025 - 2035).

Below I do not go through every variable or even every component. My goal is to explain the rationale between these choices.

- Socioeconomic scenarios: The goal here is to describe the socioeconomics at time `t[i]`. GDP and population growth rates are held constant over the 'between' duration leading up to time `t[i]`, and calculated to reproduce the SSPs.

- Emissions: Emission rates, concentrations, and radiative forcing represent the values at time `t[i]`. Emissions are approximated as increasing linearly between years, so the concentration for year `t[i]` is the average of the emissions in `t[i]` and `t[i-1]`, multiplied by the 'between' duration.

- Temperatures: Temperatures also represent the value at time `t[i]`. In previous versions of PAGE, temperature change was computed assuming that all of the emissions occured at once, in between the two periods. Starting with PAGE-ICE, radiative forcing is assumed to follow a linear approximation in between timesteps.

- Damages: Damages generally just combine the temperature and socioeconomics of the year `t[i]` and compute a corresponding loss for year `t[i]`. The only minor twist is for discontinuity impacts, where the loss decays exponentially after the discontinuity is triggered, so the 'between' timestep duration is used to calculate this decay between timesteps.

- SCC: Since all of the damages computed for the timesteps are really occurring in year `t[i]`, we need to make an assumption for what happens in all of the other years. Since the SCC is just an aggregate value, the assumption used is very simple: all of the years closest to `t[i]` also get the damage in `t[i]`-- so, the discounted damages for each timestep are multiplied by the 'centered' duration when they are added up.

When computing the annual emissions change, for calculating the SCC, the 'centered' duration is also used. This is because the emissions are linearly interpolated between periods, so the emissions are spread out over the two period surrounding the emission year. So a 100 Mt pulse in 2020 becomes a 100 Mt / 7.5 increase in 2020, but a total of 100 Mt * 5 / 2 added to the 2015-2020 period and 100 Mt * 10 / 2 added to the 2020-2030 period.
