# page-growthrates
This uses generates CSVs containing converging growth rates and prepares them in a way such that they can be directly implemented into Mimi PAGE.

The logic for this is set out here:
https://paper.dropbox.com/doc/SSP-Extensions--Ag~NOi33ZjSedC4G0TEWFI2eAQ-OI3XfYeKvhDeYBi8CqMbk

The process starts with SSP projected values from 2015 to 2100,
contained in PAGE-ICE.

Next, the script `src/bayesfit.R` applies a Bayesian model to fit the
convergent growth equations.  It does this in such a way that it (1)
recalculates the mean growth rate (for convergence) every year, (2)
fits the convergence and decay rates under that yearly process, and
(3) keeps track of the full range of Bayesian uncertainty during
prediction.

The results of this process are stored in the `data` directory.

Finally, the `prepare-growthrates.R` script translates these files
into the form needed by Mimi PAGE.
