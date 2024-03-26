setwd("~/research/iamup2/MimiPAGE2020.jl/preproc/countries/")

df1 <- read.csv("../../data/bycountry.csv")
df2 <- read.csv("../../data/aggregates.csv")

library(PBSmapping)

shp <- importShapefile("~/data/political/ne_10m_admin_0_countries_lakes/ne_10m_admin_0_countries_lakes.shp")
polydata <- attr(shp, 'PolyData')
polydata$ISO <- as.character(polydata$ADM0_A3)
polydata$ISO[polydata$ADMIN == "South Sudan"] <- "SSD"
polydata$ISO[polydata$ADMIN == "Palestine"] <- "PSE"
polydata$ISO[polydata$ADMIN == "Kosovo"] <- "XKX"
polydata$ISO[polydata$ADMIN == "Western Sahara"] <- "ESH"
## We also distinguish Tokelau, but it is in the New Zealand polygons
polydata$ISO[polydata$ADMIN == "Somaliland"] <- "SOM"

library(ggplot2)

polydata$ISO[!(polydata$ISO %in% df1$ISO3) & !(polydata$ISO %in% df2$ISO)]

known <- c(df1$ISO3, df2$ISO)
known[!(known %in% polydata$ISO)]

library(dplyr)
polydata2 <- polydata %>% left_join(df2, by='ISO') %>% left_join(df1, by=c('ISO'='ISO3'))
polydata2$colour <- NA
polydata2$colour[!is.na(polydata2$Aggregate) & polydata2$Aggregate == "SIS-NAmer"] <- "SIS North America"
polydata2$colour[!is.na(polydata2$Aggregate) & polydata2$Aggregate == "EUR-Micro"] <- "European Microstates"
polydata2$colour[!is.na(polydata2$Aggregate) & polydata2$Aggregate == "SIS-Europe"] <- "SIS Europe"
polydata2$colour[!is.na(polydata2$Aggregate) & polydata2$Aggregate == "SIS-Oceania"] <- "SIS Oceania"
polydata2$colour[!is.na(polydata2$Aggregate) & polydata2$Aggregate == "SIS-Gondwana"] <- "SIS Gondwana"
polydata2$colour[!is.na(polydata2$Country)] <- "Individual"
polydata2$colour <- factor(polydata2$colour, levels=c("Individual", "SIS Oceania", "SIS North America", "SIS Gondwana", "SIS Europe", "European Microstates"))

shp2 <- shp %>% left_join(polydata2[, c('PID', 'colour')])

gp <- ggplot(shp2, aes(X, Y, group=paste(PID, SID))) +
    geom_polygon(fill='grey') +
    geom_polygon(aes(fill=colour, colour=colour, linewidth=!is.na(colour) & colour == "Individual")) +
    scale_fill_manual("Region aggregates", breaks=c("Individual", "SIS Oceania", "SIS North America", "SIS Gondwana", "SIS Europe", "European Microstates"), values=c("#404040", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02")) +
    scale_colour_manual("Region aggregates", breaks=c("Individual", "SIS Oceania", "SIS North America", "SIS Gondwana", "SIS Europe", "European Microstates"), values=c("#ffffff", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02")) +
    scale_linewidth_manual(breaks=c(T, F), values=c(.1, .2)) +
    theme_bw() + guides(linewidth="none") + scale_x_continuous(NULL, expand=c(0, 0)) + scale_y_continuous(NULL, expand=c(0, 0))
ggsave("map.pdf", width=6.5, height=3)

ggplot(shp, aes(X, Y, group=paste(PID, SID))) +
    geom_polygon(fill='grey') +
    geom_polygon(data=subset(shp, PID %in% polydata$PID[polydata$ISO %in% df1$ISO3]), aes(fill='Individual', colour='Individual'), linewidth=.1) +
    geom_polygon(data=subset(shp, PID %in% polydata$PID[polydata$ISO %in% df2$ISO[df2$Aggregate == 'SIS-Oceania']]), aes(fill="SIS Oceania", colour="SIS Oceania"), linewidth=.2) +
    geom_polygon(data=subset(shp, PID %in% polydata$PID[polydata$ISO %in% df2$ISO[df2$Aggregate == 'SIS-NAmer']]), aes(fill="SIS North America", colour="SIS North America"), linewidth=.2) +
    geom_polygon(data=subset(shp, PID %in% polydata$PID[polydata$ISO %in% df2$ISO[df2$Aggregate == 'SIS-Gondwana']]), aes(fill="SIS Gondwana", colour="SIS Gondwana"), linewidth=.2) +
    geom_polygon(data=subset(shp, PID %in% polydata$PID[polydata$ISO %in% df2$ISO[df2$Aggregate == 'SIS-Europe']]), aes(fill="SIS Europe", colour="SIS Europe"), linewidth=.2) +
    geom_polygon(data=subset(shp, PID %in% polydata$PID[polydata$ISO %in% df2$ISO[df2$Aggregate == 'EUR-Micro']]), aes(fill="European Microstates", colour="European Microstates"), linewidth=.2) +
    scale_fill_manual(breaks=c("Individual", "SIS Oceania", "SIS North America", "SIS Gondwana", "SIS Europe", "European Microstates"), values=c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02")) +
    scale_colour_manual(breaks=c("Individual", "SIS Oceania", "SIS North America", "SIS Gondwana", "SIS Europe", "European Microstates"), values=c("#ffffff", "#d95f02", "#7570b3", "#e7298a", "#66a61e", "#e6ab02")) +
    theme_bw()
