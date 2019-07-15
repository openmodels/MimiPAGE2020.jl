library(reshape2)
library(ggplot2)
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

results <- data.frame(ssp=c(), variable=c(), converge=c(), decay=c())

for (ssp in 1:5) {

## Read in SSP data
gdp.rate <- read.csv(paste0("../ssp", ssp, "_gdp_rate.csv"), skip=2)
pop.rate <- read.csv(paste0("../ssp", ssp, "_pop_rate.csv"), skip=2)
pop0 <- read.csv("../pop_0.csv", skip=2)

## Set this up as GDPpc
gdppc.rate <- gdp.rate - pop.rate
gdppc.rate$year <- gdp.rate$year

for (variable in c('gdppc', 'pop')) {
    if (variable == 'gdppc') {
        df <- melt(gdppc.rate[1:6,], 'year') ## Melt into long form
        dfx <- gdppc.rate[1:6,]
    } else {
        df <- melt(pop.rate[1:6,], 'year') ## Melt into long form
        dfx <- pop.rate[1:6,]
    }

    names(df) <- c('year', 'region', 'rate')

    ## Fill in extra columns
    df$rate.lag <- NA
    df$meanrate.lag <- NA
    df$ydiff <- NA

    years <- unique(df$year)
    for (yi in 2:length(years)) {
        df$ydiff[df$year == years[yi]] <- years[yi] - years[yi-1]
        df$rate.lag[df$year == years[yi]] <- df$rate[df$year == years[yi-1]]
        df$meanrate.lag[df$year == years[yi]] <- sum(df$rate[df$year == years[yi-1]] * pop0$pop_0 / sum(pop0$pop_0))
    }

    df <- df[!is.na(df$ydiff),]

    ## Bayesian model
    stan.code <- "
data {
  int<lower=0> N; // observations
  int<lower=0> M; // regions

  int<lower=1, upper=M> region[N];

  vector[N] rate; // growth rate
  vector[N] rate_lag; // previous period growth rate
  vector[N] meanrate_lag; // previous period average growth rate
  vector[N] ydiff; // years between periods
}
parameters {
  real<lower=0, upper=0.5> converge; // rate of convergence
  real<lower=0, upper=0.5> decay; // rate of decay

  real<lower=0> sigma[M];
}
model {
  // Assume that every growth observation derives from this model
  for (ii in 1:N) {
    rate[ii] ~ normal(rate_lag[ii] * (1 - ydiff[ii] * (converge + decay)) + meanrate_lag[ii] * ydiff[ii] * converge, sigma[region[ii]]);
  }
}"

    ## Setup data
    df$region <- factor(df$region)
    stan.data <- list(N=nrow(df), M=length(unique(df$region)),
                      region=as.numeric(df$region), rate=df$rate,
                      rate_lag=df$rate.lag, meanrate_lag=df$meanrate.lag, ydiff=df$ydiff)

    ## Fit model
    fit <- stan(model_code=stan.code, data=stan.data, iter=1000, chains=4)
    la0 <- extract(fit, permute=T)

    ## Bayesian model
    stan.code.iterative <- "
data {
  int<lower=0> N; // periods
  int<lower=0> M; // regions
  int<lower=0> Tmaxp1; // max ydiff years plus 1

  vector[M] rate[N]; // growth rate
  vector[M] rate_lag[N]; // previous period growth rate
  int<lower=0> ydiff[N]; // years between periods
  vector[M] weights; // weights for weight averaging

  real converge_mu;
  real converge_sigma;
  real decay_mu;
  real decay_sigma;
  real logsigma_mu[M];
  real logsigma_sigma[M];
}
parameters {
  real<lower=0, upper=0.5> converge; // rate of convergence
  real<lower=0, upper=0.5> decay; // rate of decay

  real<lower=0> sigma[M];
}
transformed parameters {
  vector[M] rate_pred[N,Tmaxp1]; // predicted rate

  for (ii in 1:N) {
    rate_pred[ii, 1] = rate_lag[ii];
    for (tt in 1:ydiff[ii]) {
       rate_pred[ii, tt+1] = rate_pred[ii, tt] * (1 - converge - decay) + converge * dot_product(rate_pred[ii, tt], weights);
    }
    if (ydiff[ii] + 1 < Tmaxp1) {
      for (tt in (ydiff[ii]+1):Tmaxp1)
        rate_pred[ii, tt] = 0 * weights;
    }
  }
}
model {
  // Assume that every growth observation derives from this model
  for (ii in 1:N) {
    rate[ii] ~ normal(rate_pred[ii, ydiff[ii] + 1], sigma);
  }
  converge ~ normal(converge_mu, converge_sigma);
  decay ~ normal(decay_mu, decay_sigma);
  sigma ~ lognormal(logsigma_mu, logsigma_sigma);
}"

    stan.data <- list(N=nrow(dfx)-1, M=ncol(dfx)-1, Tmaxp1=26,
                      rate=dfx[-1, -1], rate_lag=dfx[-nrow(dfx), -1],
                      ydiff=dfx$year[-1] - dfx$year[-nrow(dfx)],
                      weights=pop0$pop_0 / sum(pop0$pop_0),
                      converge_mu=mean(la0$converge), converge_sigma=sd(la0$converge),
                      decay_mu=mean(la0$decay), decay_sigma=sd(la0$decay),
                      logsigma_mu=apply(log(la0$sigma), 2, mean), logsigma_sigma=apply(log(la0$sigma), 2, sd))


    ## Fit model
    fit <- stan(model_code=stan.code.iterative, data=stan.data, iter=1000, chains=4,
                init=function() {
                    list(converge=sample(la0$converge, 1),
                         decay=sample(la0$decay, 1),
                         sigma=la0$sigma[sample(1:nrow(la0$sigma), 1),])
                }, pars=c('converge', 'decay', 'sigma'))
    la <- extract(fit, permute=T)

    ## Check results
    mean(la$converge)
    quantile(la$converge, probs=c(.025, .975))

    mean(la$decay)
    quantile(la$decay, probs=c(.025, .975))

    results <- rbind(results, data.frame(ssp, variable, converge=mean(la$converge), decay=mean(la$decay)))

    ## Predict it into the future
    dfpred <- df[, 1:3]
    dfpred$rate.lb <- df$rate
    dfpred$rate.ub <- df$rate

    rate_lags <- t(matrix(dfpred$rate[dfpred$year == 2100], 8, 2000))
    for (year in 2101:2300) {
        meanrate_lag <- as.numeric(rate_lags %*% pop0$pop_0 / sum(pop0$pop_0))
        rates <- matrix(NA, 2000, 8)
        for (rr in 1:8) {
            rates[, rr] <- rate_lags[, rr] * (1 - la$converge - la$decay) + meanrate_lag * la$converge

            rate.lb <- quantile(rates[, rr], probs=.025)
            rate.ub <- quantile(rates[, rr], probs=.975)
            dfpred <- rbind(dfpred, data.frame(year, region=unique(dfpred$region)[rr], rate=mean(rates[, rr]),
                                               rate.lb, rate.ub))
        }

        rate_lags = rates
    }

    ## Plot the results

    gp <- ggplot(dfpred, aes(year, rate)) +
        geom_ribbon(aes(ymin=rate.lb, ymax=rate.ub, fill=region), alpha=.5) +
        geom_line(aes(colour=region)) +
        theme_bw() + xlab(NULL) +
        scale_colour_discrete(name=NULL) + scale_fill_discrete(name=NULL)
    if (variable == 'gdppc')
        gp <- gp + ylab("GDP per capita growth")
    else
        gp <- gp + ylab("Population growth")

    ggsave(paste0("ssp", ssp, "-", variable, ".pdf"), gp, width=6, height=4)

    write.csv(dfpred, paste0("ssp", ssp, "-", variable, ".csv"), row.names=F)
}

}
