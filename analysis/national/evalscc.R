setwd("~/research/iamup2/MimiPAGE2020.jl")

library(dplyr)
library(ggplot2)
library(reshape2)
library(cowplot)
library(scales)

outdir <- "output"

baseline <- read.csv("data/bycountry.csv")

get.result.row <- function(df, max.mc=NULL) {
    df2 <- df %>% filter(country == 'global')
    df3 <- df %>% filter(country != 'global') %>% group_by(country) %>% summarize(scc=median(scc, na.rm=T)) %>%
        left_join(baseline, by=c('country'='ISO3'))

    ## plot(density(df3$scc / df3$Pop2015))
    ## mean(df3$scc / df3$Pop2015) / sd(df3$scc / df3$Pop2015)
    ## plot(density(df3$scc / df3$GDP2015))
    ## mean(df3$scc / df3$GDP2015) / sd(df3$scc / df3$GDP2015)

    df3$GDPpc2015 <- df3$GDP2015 / df3$Pop2015

    df3$logscc <- log(df3$scc)
    df3$logscc[!is.finite(df3$logscc)] <- NA
    mod <- lm(logscc ~ log(Pop2015) + log(GDPpc2015), data=df3)
    ## summary(mod) # R2 = 0.9737

    if (is.null(mod$na.action)) {
        df3$expresid <- exp(mod$resid)
    } else {
        df3$expresid <- NA
        df3$expresid[-mod$na.action] <- exp(mod$resid)
    }
    mod2 <- lm(expresid ~ Temp2010, data=df3)
    ## summary(mod2)

    ## Model:
    ## SCC = (alpha0 + alpha1 T) (Pop^beta) (GDPpc^gamma)

    soln <- optim(c(1, mod2$coeff[2], mod$coeff[-1]), function(par) {
        scchat <- exp(mod$coeff[1]) * (par[1] + par[2] * df3$Temp2010) * df3$Pop2015^par[3] * df3$GDPpc2015^par[4] * exp(var(mod$resid) / 2)
        sccobs <- sign(df3$scc) * log(abs(df3$scc) + 1)
        sccprd <- sign(scchat) * log(abs(scchat) + 1)
        sum((sccobs - sccprd)^2, na.rm=T)
    }, hessian=T)

    ## Calculate pars for each mc
    df4 <- df %>% filter(country != 'global')
    df4$mc <- rep(1:(nrow(df4) / 183), each=183)
    pardf <- data.frame()
    for (mcii in unique(df4$mc)) {
        if (!is.null(max.mc) && mcii > max.mc)
            break
        df5 <- df4 %>% filter(mc == mcii & country != 'global') %>% left_join(baseline, by=c('country'='ISO3'))
        if (sum(df5$scc > 0, na.rm=T) < 3) {
            pardf <- rbind(pardf, data.frame(median=NA, mean=NA, stddev=NA,
                                             alpha1=NA, alpha1.se=NA, betam1=NA,
                                             beta.se=NA, gammam1=NA, gamma.se=NA, rsqr=NA))
            next
        }

        df5$GDPpc2015 <- df5$GDP2015 / df5$Pop2015

        df5$logscc <- log(df5$scc)
        df5$logscc[!is.finite(df5$logscc)] <- NA
        mod.mc <- lm(logscc ~ log(Pop2015) + log(GDPpc2015), data=df5)
        expvarresid2 <- exp(var(mod.mc$resid) / 2)

        sccobs <- sign(df5$scc) * log(abs(df5$scc) + 1)
        soln.mc <- optim(soln$par, function(par) {
            scchat <- exp(mod.mc$coeff[1]) * (par[1] + par[2] * df5$Temp2010) * df5$Pop2015^par[3] * df5$GDPpc2015^par[4] * expvarresid2
            sccprd <- sign(scchat) * log(abs(scchat) + 1)
            sum((sccobs - sccprd)^2, na.rm=T)
        }, hessian=F)

        par.mc <- soln.mc$par
        scchat <- exp(mod$coeff[1]) * (par.mc[1] + par.mc[2] * df5$Temp2010) * df5$Pop2015^par.mc[3] * df5$GDPpc2015^par.mc[4] * exp(var(mod$resid) / 2)
        if (sum(scchat > 0 & !is.na(df5$scc) & df5$scc > 0) > 2)
            rsqr <- summary(lm(logscc ~ 0 + log(scchat), data=df5))$r.squared
        else
            rsqr <- NA

        pardf <- rbind(pardf, data.frame(median=NA, mean=NA, stddev=NA,
                                         alpha1=par.mc[2], alpha1.se=NA, betam1=par.mc[3] - 1,
                                         beta.se=NA, gammam1=par.mc[4] - 1, gamma.se=NA, rsqr=rsqr))
    }
    if (!is.null(max.mc)) {
        pardf <- rbind(pardf, data.frame(median=rep(NA, nrow(df) - max.mc), mean=NA, stddev=NA,
                                         alpha1=NA, alpha1.se=NA, betam1=NA,
                                         beta.se=NA, gammam1=NA, gamma.se=NA, rsqr=NA))
    }

    pardf$median <- df$scc[df$country == 'global']
    pardf$mean <- df$scc[df$country == 'global']

    par <- soln$par
    df3$scchat <- exp(mod$coeff[1]) * (par[1] + par[2] * df3$Temp2010) * df3$Pop2015^par[3] * df3$GDPpc2015^par[4] * exp(var(mod$resid) / 2)

    rsqr <- summary(lm(logscc ~ 0 + log(scchat), data=df3))$r.squared

    vcv <- solve(soln$hessian)
    stderr <- sqrt(diag(vcv))

    rbind(data.frame(median=median(df2$scc, na.rm=T), mean=mean(df2$scc, na.rm=T), stddev=sd(df2$scc, na.rm=T),
                     alpha1=par[2], alpha1.se=stderr[2],
                     betam1=par[3] - 1, beta.se=stderr[3], gammam1=par[4] - 1, gamma.se=stderr[4], rsqr),
          pardf)
}

gp.saved <- NULL
get.displays <- function(alts, levels) {
    pdf1.raw <- data.frame()
    pdf2 <- data.frame()
    pdf2.mc <- data.frame()
    pdf2.diff <- data.frame()
    basedf <- NULL
    for (ii in 1:length(alts)) {
        print(levels[ii])
        altdf <- read.csv(alts[ii])
        pdf1.raw <- rbind(pdf1.raw, cbind(subset(altdf, country == 'global'), group=levels[ii]))
        rows <- get.result.row(altdf)
        pdf2 <- rbind(pdf2, cbind(rows[1,], group=levels[ii]))
        if (is.null(basedf)) {
            basedf <- rows[-1,]
            pdf2.mc <- rbind(pdf2.mc, cbind(rows[-1,], group=levels[ii]))
        } else {
            pdf2.mc <- rbind(pdf2.mc, cbind(rows[-1,], group=levels[ii]))
            alpha1.diff <- rows$alpha1[-1] - basedf$alpha1
            beta.diff <- rows$betam1[-1] - basedf$betam1
            gamma.diff <- rows$gammam1[-1] - basedf$gammam1
            pdf2.diff <- rbind(pdf2.diff, data.frame(alpha1=alpha1.diff, alpha1.se=NA,
                                                     betam1=beta.diff, beta.se=NA,
                                                     gammam1=gamma.diff, gamma.se=NA, group=levels[ii]))
        }
    }

    pdf1 <- pdf1.raw %>%
        group_by(group) %>% summarize(mu=mean(scc, na.rm=T), p025=quantile(scc, 0.025, na.rm=T),
                                      p05=quantile(scc, 0.05, na.rm=T),
                                      p25=quantile(scc, 0.25, na.rm=T), p50=quantile(scc, 0.5, na.rm=T),
                                      p75=quantile(scc, 0.75, na.rm=T), p95=quantile(scc, 0.95, na.rm=T),
                                      p975=quantile(scc, 0.975, na.rm=T))
    pdf1$group <- factor(pdf1$group, levels=rev(levels))
    gp1a <- ggplot(pdf1, aes(group)) +
        coord_flip(ylim=c(max(min(pdf1$p025, na.rm=T), -500), 5e3 - 1)) + scale_y_continuous(expand=c(0, 0)) +
        geom_boxplot(aes(min=p05, lower=p25, middle=p50, upper=p75, max=p95), stat="identity") +
        geom_point(aes(y=mu)) +
        geom_segment(aes(xend=group, y=p025, yend=p05), lty=2, lwd=0.4) +
        geom_segment(aes(xend=group, y=p975, yend=p95), lty=2, lwd=0.4) +
        theme_bw() + ylab("Global SCC ($2015/tCO2)") + xlab(NULL)
    gp1a

    gp1b <- ggplot(pdf1, aes(group)) +
        coord_flip(ylim=c(5e3, min(max(pdf1$p975, na.rm=T), 1e4, na.rm=T))) + scale_y_continuous(expand=c(0, 0)) +
        geom_boxplot(aes(min=p05, lower=p25, middle=p50, upper=p75, max=p95), stat="identity") +
        geom_point(aes(y=mu)) +
        geom_segment(aes(xend=group, y=p025, yend=p05), lty=2, lwd=0.4) +
        geom_segment(aes(xend=group, y=p975, yend=p95), lty=2, lwd=0.4) +
        theme_bw() + ylab("")
    gp1b

    pdf2.long <- cbind(melt(pdf2.mc[, c('group', 'alpha1', 'betam1', 'gammam1')], id='group'),
                       se=melt(pdf2.mc[, c('group', 'alpha1.se', 'beta.se', 'gamma.se')], id='group')$value)
    pdf2.long$group <- factor(pdf2.long$group, levels=rev(levels))

    pdf2.diff.long <- cbind(melt(pdf2.diff[, c('group', 'alpha1', 'betam1', 'gammam1')], id='group'),
                            se=melt(pdf2.diff[, c('group', 'alpha1.se', 'beta.se', 'gamma.se')], id='group')$value)
    pdf2.diff.long$group <- factor(pdf2.diff.long$group, levels=rev(levels))

    pdf3 <- rbind(cbind(pdf2.long, calc="raw"),
                  cbind(pdf2.diff.long, calc="diff")) %>% group_by(calc, group, variable) %>%
        summarize(mu=mean(value, na.rm=T), med=median(value, na.rm=T),
                  ci25=quantile(value, .25, na.rm=T), ci75=quantile(value, .75, na.rm=T))
    pdf3$label <- factor(ifelse(pdf3$variable == "alpha1", "alpha_1", ifelse(pdf3$variable == "betam1", "beta - 1", "gamma - 1")),
                         levels=c("alpha_1", "beta - 1", "gamma - 1"))

    gp2 <- ggplot(pdf3, aes(group, group=paste(group, calc))) +
        facet_wrap(~ label, ncol=3, scales='free_x') +
        coord_flip() +
        geom_errorbar(aes(ymin=ci25, ymax=ci75, colour=calc), position="dodge") +
        geom_point(aes(y=med, colour=calc), position=position_dodge(width=.9)) +
        geom_hline(data=data.frame(label=c('alpha_1', 'beta - 1', 'gamma - 1'), value=c(0, 0, 0)), aes(yintercept=value), linetype='dashed') +
        scale_colour_manual(breaks=c('raw', 'diff'), values=c('#000000', '#800000')) +
        scale_y_continuous(breaks=breaks_extended(3)) + # + scale_x_discrete(limits=rev(levels[c(1, 5, 2, 3, 4)])) + <-- XXX: when plotting partial damages
        theme_bw() + theme(panel.spacing=unit(.7, "lines")) + guides(colour='none') + ylab("Coefficient values")
    gp2

    drop.y.labels <- theme(
        axis.title.y = element_blank(),  # Remove y-axis title
        axis.text.y = element_blank(),    # Remove y-axis text
        axis.ticks.y = element_blank()     # Remove y-axis ticks
    )
    gp <- plot_grid(gp1a + facet_wrap(~ "Distribution") + theme(plot.margin=margin(r=0)),
                    gp1b + drop.y.labels + facet_wrap(~ "Distribution") + theme(plot.margin=margin(l=0)),
                    gp2 + drop.y.labels + theme(plot.margin=margin(0, 1, 0, 6)),
                    rel_widths=c(1, 0.5, 1), nrow=1, ncol=3)
    gp.saved <<- gp
    print(gp)
    pdf1 %>% left_join(pdf2, by='group')
}

get.diffdisplays <- function(alts, levels, max.mc=1000) {
    pdf1.raw <- data.frame()
    pdf2 <- data.frame()
    pdf2.mc <- data.frame()
    pdf2.diff <- data.frame()
    basedf <- NULL
    for (ii in 1:length(alts)) {
        print(levels[ii])
        altdf <- read.csv(alts[ii])
        pdf1.raw <- rbind(pdf1.raw, cbind(subset(altdf, country == 'global'), group=levels[ii]))
        rows <- get.result.row(altdf, max.mc)
        pdf2 <- rbind(pdf2, cbind(rows[1,], group=levels[ii]))
        if (is.null(basedf)) {
            basedf <- rows[-1,]
            pdf2.mc <- rbind(pdf2.mc, cbind(rows[-1,], group=levels[ii]))
        } else {
            pdf2.mc <- rbind(pdf2.mc, cbind(rows[-1,], group=levels[ii]))
            mean.diff <- rows$mean[-1] - basedf$mean
            alpha1.diff <- rows$alpha1[-1] - basedf$alpha1
            beta.diff <- rows$betam1[-1] - basedf$betam1
            gamma.diff <- rows$gammam1[-1] - basedf$gammam1
            pdf2.diff <- rbind(pdf2.diff, data.frame(mean=mean.diff, mean.se=NA, alpha1=alpha1.diff, alpha1.se=NA,
                                                     betam1=beta.diff, beta.se=NA,
                                                     gammam1=gamma.diff, gamma.se=NA, group=levels[ii]))
        }
    }

    pdf2.diff.long <- cbind(melt(pdf2.diff[, c('group', 'mean', 'alpha1', 'betam1', 'gammam1')], id='group'),
                            se=melt(pdf2.diff[, c('group', 'mean.se', 'alpha1.se', 'beta.se', 'gamma.se')], id='group')$value)
    pdf2.diff.long$group <- factor(pdf2.diff.long$group, levels=rev(levels))

    pdf3 <- pdf2.diff.long %>% group_by(group, variable) %>%
        summarize(mu=mean(value, na.rm=T), med=median(value, na.rm=T),
                  ci25=quantile(value, .25, na.rm=T), ci75=quantile(value, .75, na.rm=T))

    pdf3
}


df <- read.csv(file.path(outdir, "allscc.csv"))
df %>% filter(country == 'global') %>% summarize(mu=median(scc, na.rm=T), ci25=quantile(scc, .25, na.rm=T), ci75=quantile(scc, .75, na.rm=T))
df %>% filter(country == 'KOR') %>% summarize(mu=median(scc, na.rm=T), ci25=quantile(scc, .25, na.rm=T), ci75=quantile(scc, .75, na.rm=T))

df <- read.csv(file.path(outdir, "allscc-nodrupp.csv"))
df %>% filter(country == 'KOR') %>% summarize(mu=median(scc, na.rm=T), ci25=quantile(scc, .25, na.rm=T), ci75=quantile(scc, .75, na.rm=T))

df <- read.csv(file.path(outdir, "allscc.csv"))
pdf <- get.result.row(df)
pdf$mcii <- c(NA, 1:10000)
pdf.long <- melt(pdf[-1, c('mcii', 'mean', 'alpha1', 'betam1', 'gammam1')], id='mcii')

pdf3 <- pdf.long %>% mutate(value=ifelse(variable %in% c('mean', 'alpha1'), value, value + 1)) %>% group_by(variable) %>%
    summarize(mu=mean(value, na.rm=T), med=median(value, na.rm=T),
              ci25=quantile(value, .25, na.rm=T), ci75=quantile(value, .75, na.rm=T))

pdf3$label <- as.character(list('mean'="Global SCC", 'alpha1'="Temperature", 'betam1'="Population", 'gammam1'="GDP per capita")[pdf3$variable])
pdf3$label <- factor(pdf3$label, levels=c('Global SCC', 'Temperature', 'Population', 'GDP per capita'))

ggplot(pdf3, aes("Default")) +
    facet_wrap(~ label, scales='free_x', ncol=4) +
    coord_flip() +
    geom_errorbar(aes(ymin=ci25, ymax=ci75)) +
    geom_point(aes(y=med)) +
    geom_hline(data=data.frame(label=factor(c('Global SCC', 'Temperature', 'Population', 'GDP per capita'), levels=c('Global SCC', 'Temperature', 'Population', 'GDP per capita')),
                               value=c(0, 0, 1, 1)),
               aes(yintercept=value), linetype='dashed') +
    theme_bw() + theme(panel.spacing=unit(.2, "lines")) + guides(colour='none') + ylab("Coefficient values") + xlab(NULL)


disp.year <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-2050-v2.csv"), file.path(outdir, "allscc-2100-v2.csv")),
                          c('2020', '2050', '2100'))
ggsave("sccfig-year.pdf", width=8, height=2)

diff.year <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-2050-v2.csv"), file.path(outdir, "allscc-2100-v2.csv")),
                              c('2020', '2050', '2100'))

disp.scen <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-ssp126.csv"), file.path(outdir, "allscc-ssp245.csv"), file.path(outdir, "allscc-ssp585.csv")),
                          c('RFFSP', 'SSP1-2.6', 'SSP2-4.5', 'SSP5-8.5'))
ggsave("sccfig-scen.pdf", width=8, height=2)

diff.scen <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-ssp126.csv"), file.path(outdir, "allscc-ssp245.csv"), file.path(outdir, "allscc-ssp585.csv")),
                              c('RFFSP', 'SSP1-2.6', 'SSP2-4.5', 'SSP5-8.5'))
if (F) {
    source("analysis/map.R", chdir=T)

    alt1 <- read.csv(file.path(outdir, "allscc.csv"))
    alt2 <- read.csv(file.path(outdir, "allscc-ssp245.csv"))
    alt1$diff <- alt2$scc - alt1$scc
    df2 <- df %>% filter(country != 'global') %>% group_by(country) %>% summarize(scc=median(scc, na.rm=T))
    df3 <- alt1 %>% group_by(country) %>% summarize(diff=median(diff, na.rm=T))

    polydata3 <- polydata2 %>% left_join(df3, by=c('code'='country'))
    polydata3$scc <- polydata3[, 'diff']
    shp2 <- shp %>% left_join(polydata3[, c('PID', 'scc')])

    centroids2 <- centroids %>% left_join(polydata3[, c('PID', 'scc')])

    ggplot(shp2, aes(X, Y)) +
        geom_polygon(aes(fill=scc, group=paste(PID, SID))) +
        geom_label(data=subset(centroids2, show & !is.na(scc)), aes(label=format(round(scc, 2), nsmall=2, trim=T)), size=2, label.padding=unit(0.1, "lines")) +
        theme_bw() + scale_x_continuous(NULL, expand=c(0, 0)) + scale_y_continuous(NULL, expand=c(0, 0)) +
        scale_fill_distiller("Difference in Social\nCost of Carbon\n(2015 USD / t CO2)", palette="YlOrRd", direction=1, labels=scales::comma)
    ggsave("newfigs/ssp245diff.pdf", width=10, height=5.5)
}



disp.mktd <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-marketdmg-pageice.csv"), file.path(outdir, "allscc-marketdmg-nooffset.csv"), file.path(outdir, "allscc-marketdmg-constoffset.csv")),
                          c('Adaptive', 'PAGE-ICE', 'No offset', 'Constant offset'))
ggsave("sccfig-mktd.pdf", width=8, height=2)

diff.mktd <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-marketdmg-pageice.csv"), file.path(outdir, "allscc-marketdmg-nooffset.csv"), file.path(outdir, "allscc-marketdmg-constoffset.csv")),
                          c('Adaptive', 'PAGE-ICE', 'No offset', 'Constant offset'))


disp.othd <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-otherdmg-pageice.csv"), file.path(outdir, "allscc-otherdmg-pinational.csv"), file.path(outdir, "allscc-otherdmg-pinonmarket.csv"), file.path(outdir, "allscc-otherdmg-pislr.csv")),
                          c('Adaptive', 'PAGE-ICE', 'National PAGE-ICE', 'PAGE-ICE Non-Market', 'PAGE-ICE SLR'))
ggsave("sccfig-othd.pdf", width=8, height=2)

diff.othd <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-otherdmg-pageice.csv"), file.path(outdir, "allscc-otherdmg-pinational.csv"), file.path(outdir, "allscc-otherdmg-pinonmarket.csv"), file.path(outdir, "allscc-otherdmg-pislr.csv")),
                          c('Adaptive', 'PAGE-ICE', 'National PAGE-ICE', 'PAGE-ICE Non-Market', 'PAGE-ICE SLR'))


disp.macu <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-mac-pageice.csv")),
             c('Updated', 'PAGE-ICE'))
ggsave("sccfig-macu.pdf", width=8, height=1.5)

diff.macu <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-mac-pageice.csv")),
             c('Updated', 'PAGE-ICE'))


disp.down <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-downscale-pageice.csv")),
                          c('Updated', 'PAGE-ICE'))
ggsave("sccfig-down.pdf", width=8, height=1.5)
diff.down <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-downscale-pageice.csv")),
                          c('Updated', 'PAGE-ICE'))

disp.subn <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-nosubnational.csv")),
                          c('Subnational', 'National'))
ggsave("sccfig-subn.pdf", width=8, height=1.5)
diff.subn <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-nosubnational.csv")),
                          c('Subnational', 'National'))

disp.trad <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-notrade.csv")),
                          c('With Trade', 'Independent'))
ggsave("sccfig-trad.pdf", width=8, height=1.5)
diff.trad <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-notrade.csv")),
                          c('With Trade', 'Independent'))

disp.part <- get.displays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-onlydmg-nonmarket.csv"),
                            file.path(outdir, "allscc-onlydmg-slr.csv"), file.path(outdir, "allscc-onlydmg-market.csv")), # file.path(outdir, "allscc-onlydmg-discont.csv")
                          c('Combined', 'Non-market-only', 'SLR-only', 'Market-only')) # 'Discontinuity-only'
ggsave(file.path(outdir, "figures/sccfig-part.pdf"), width=8, height=2.5)
diff.part <- get.diffdisplays(c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-onlydmg-nonmarket.csv"),
                            file.path(outdir, "allscc-onlydmg-slr.csv"), file.path(outdir, "allscc-onlydmg-market.csv")), # file.path(outdir, "allscc-onlydmg-discont.csv")
                          c('Combined', 'Non-market-only', 'SLR-only', 'Market-only')) # 'Discontinuity-only'

write.csv(rbind(disp.scen, disp.year, disp.mktd, disp.othd, disp.macu, disp.down, disp.subn, disp.trad, disp.part), "scc-options.csv", row.names=F)

for (filepath in c(file.path(outdir, "allscc.csv"), file.path(outdir, "allscc-2050-v2.csv"), file.path(outdir, "allscc-2100-v2.csv"))) {
    df <- read.csv(filepath)
    df2 <- df %>% filter(country == 'global')
    print(c(filepath, mean(df2$scc == 0, na.rm=T)))
}

prevtbl <- read.csv("scc-options.csv")

disptbl <- prevtbl[-which(prevtbl[1,2] == prevtbl[, 2])[-1],]
disptbl$group[1] <- "Default Updated"
library(xtable)
print(xtable(disptbl[, c(1, 3:9, 11)]), include.rownames=F)
print(xtable(disptbl[, c(1, 13:19)]), include.rownames=F)

pdf.diff <- rbind(cbind(alts="Pulse Years", diff.year),
                  cbind(alts="Scenarios", diff.scen),
                  cbind(alts="Market Damages", diff.mktd),
                  cbind(alts="Other Damages", diff.othd),
                  cbind(alts="Abatement Costs", diff.macu),
                  cbind(alts="Downscaling", diff.down),
                  cbind(alts="Subnational Distributions", diff.subn),
                  cbind(alts="International Trade", diff.trad),
                  cbind(alts="Damage Contributions", diff.part))
write.csv(pdf.diff, "diffinfo.csv", row.names=F)

## pdf.diff <- read.csv("diffinfo.csv")
pdf.diff$label <- as.character(list('mean'="Global SCC", 'alpha1'="Temperature", 'betam1'="Population", 'gammam1'="GDP per capita")[pdf.diff$variable])
pdf.diff$label <- factor(pdf.diff$label, levels=c('Global SCC', 'Temperature', 'Population', 'GDP per capita'))
## pdf.diff$group <- gsub("PAGE-ICE", "Regional", pdf.diff$group)
## pdf.diff$group[pdf.diff$group == "National Regional"] <- "National PAGE-ICE"
pdf.diff$altlabel <- as.character(list("Pulse Years"="Year", "Scenarios"="Scenarios", "Market Damages"="Market Dmg.",
                                       "Other Damages"="Other Dmg.", "Abatement Costs"="Cost", "Downscaling"="Clim",
                                       "Subnational Distributions"="Subn", "International Trade"="Trad", "Damage Contributions"="Conntributions")[pdf.diff$alts])
pdf.diff$altlabel <- factor(pdf.diff$altlabel, levels=c('Year', 'Scenarios', 'Clim', "Market Dmg.", "Other Dmg.", 'Cost', 'Trad', 'Subn'))
#pdf.diff$group <- factor(pdf.diff$group, levels=c("SSP1-2.6", "SSP2-4.5", "SSP5-8.5",

ggplot(subset(pdf.diff, !(alts %in% c("Damage Contributions", "Pulse Years"))), aes(group)) +
    facet_grid(altlabel ~ label, scales='free', space='free_y') +
    coord_flip() +
    geom_errorbar(aes(ymin=ci25, ymax=ci75)) +
    geom_point(aes(y=med)) +
    geom_hline(data=data.frame(value=c(0, 0, 0, 0)),
               aes(yintercept=value), linetype='dashed') +
    theme_bw() + theme(panel.spacing=unit(.2, "lines")) + guides(colour='none') + ylab("Coefficient values") + xlab("Assumption Variant")
ggsave("analysis/national/diffs.pdf", width=8, height=5)
