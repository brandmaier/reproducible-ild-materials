#
# Reproducible Workflows for Intensive Longitudinal Data Analysis in R
# A Use Case
#
# Data:   Kossakowski, Groot, Haslbeck, Borsboom & Wichers (2017).
#         "Data from 'Critical Slowing Down as a Personalized Early Warning
#         Signal for Depression'". J. Open Psychology Data, 5(1).
#         doi:10.5334/jopd.29  |  OSF: https://osf.io/j4fg8  |  CC BY 4.0
#         N = 1 person, ~1478 beeps over 239 days, ~10 beeps/day, 50 items.
#
# Script: Recreate a plot from Kossakowski et al.'s Figure 1. Run a
#  linear model to estimate a linear time trend in the weekly depression
#  ratings. Note that the study has different phases, which are not
#  modeled here; the analysis serves only as an illustration.
#
# Goal: Demonstrate tools for reproducible research workflows in
#  intensive longitudinal data. No substantive conclusions.
#
# Author: Andreas M. Brandmaier <andreas.brandmaier@medicalschool-berlin.de>
#
# This script is part of the Open Materials accompanying the book chapter
# Brandmaier, A. M. (in press). Reproducible Workflows for Intensive
# Longitudinal Data Analysis in R. In T. Koch, T. Lischetzke, & J. Holtmann
# (Eds.), Handbook of intensive longitudinal data analysis. Routledge.
#
# HOW THIS FILE IS USED
# The code is split into chunks by the "#----label----" markers. The R Markdown
# report (esm_depression_trend.Rmd) lists this file under `repro: scripts:` in
# its YAML header, registers it with automate_load_scripts(), and pulls each
# chunk in via an empty chunk of the same name. Packages and data are provided
# by the YAML header, too (`repro: packages:` and `repro: data:`).
#

#----standalone----
# Only needed to run this script on its own (not used by the report):
# provides the packages and the object `raw` that the report gets from YAML.
if (!exists("raw")) {
  library(tidyr)
  library(dplyr)
  library(ggplot2)
  library(scales)
  raw <- read.csv("data/ESMdata.csv")
}

#----preprocess----
# sort by date and beep number so that "first" means "earliest beep"
raw$date <- as.Date(raw$date, format = "%d/%m/%y")
stopifnot(!anyNA(raw$date))                      # fail early on parsing errors
raw <- raw[order(raw$date, raw$beepno), ]
raw$day <- as.numeric(raw$date - min(raw$date))  # starting from zero

# beep-level series with the weekly rating carried forward (for plotting)
beeps <- tidyr::fill(raw, dep, .direction = "down")

#----weekly----
# weekly series: one row per actual weekly assessment. This must be derived
# from the *unfilled* data, otherwise carried-forward values leak in.
weekly <- raw |>
  filter(!is.na(dep)) |>
  distinct(date, dep, .keep_all = TRUE) |>
  mutate(week = floor(day / 7) + 1)

#----plot----
# SCL-90-R depression panel of Figure 1a in Kossakowski et al. (2017;
# doi: 10.5334/jopd.29). The dashed line is the linear trend of the weekly
# ratings, i.e., the same data and model as reported below.
p <- ggplot(beeps, aes(x = date, y = dep)) +
  geom_line(linewidth = 2, color = "#0171b6") +
  geom_smooth(data = weekly, method = "lm", formula = y ~ x,
              color = "darkblue", linetype = "dashed", se = FALSE) +
  scale_y_continuous(breaks = scales::breaks_width(0.2)) +
  coord_cartesian(ylim = c(1, 2.8)) +
  labs(title = "SCL-90-R depression subscale",
       x = "Date", y = "Average item score") +
  theme_classic() +
  theme(panel.grid.major.y = element_line(color = "grey80", linewidth = 0.5),
        panel.grid.minor.y = element_blank())+
  scale_x_date(
    labels = scales::label_date("%b %Y", locale = "en")
  )
p

#----model----
# A simple linear model to estimate the time trend over all phases of the
# study, testing the linear component of change in depression over time
model <- lm(dep ~ week, data = weekly)
summary(model)

#----save----
dir.create("output", showWarnings = FALSE)
saveRDS(model, "output/model_esm.rds")
ggsave("output/fig_depression.pdf", p, width = 8, height = 4)
