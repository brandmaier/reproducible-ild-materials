# _targets.R
#
# Pipeline definition for the ESM depression use case.
# Run the whole pipeline (including the HTML report) with:
#
#   targets::tar_make()
#
# Inspect it with targets::tar_visnetwork() or targets::tar_manifest().
#
# Author: Andreas M. Brandmaier
# Part of the Open Materials accompanying: Brandmaier, A. M. (in press).
# Towards reproducible data analysis of intensive longitudinal data in R.
# In T. Koch, T. Lischetzke, & J. Holtmann (Eds.), Handbook of intensive
# longitudinal data analysis. Routledge.

library(targets)
library(tarchetypes)

# load all functions from the R/ folder; targets tracks changes to them
tar_source("R")

# packages that every target needs (cocoon is called in the report)
tar_option_set(
  packages = c("dplyr", "tidyr", "ggplot2", "cocoon")
)

list(
  # --- file loading --------------------------------------------------------
  # format = "file": the pipeline re-runs if the content of the file changes
  tar_target(
    data_file,
    "data/ESMdata.csv",
    format = "file"
  ),
  tar_target(raw_data, read_esm(data_file)),

  # --- preprocessing -------------------------------------------------------
  tar_target(esm,    preprocess_esm(raw_data)),  # dates, sorting, day counter
  tar_target(beeps,  make_beeps(esm)),           # weekly rating carried forward
  tar_target(weekly, make_weekly(esm)),          # one row per weekly assessment

  # --- plotting ------------------------------------------------------------
  tar_target(fig_depression, make_depression_plot(beeps, weekly)),
  tar_target(
    fig_file,
    save_plot(fig_depression, "output/fig_depression.pdf"),
    format = "file"
  ),

  # --- modeling ------------------------------------------------------------
  tar_target(model, fit_trend_model(weekly)),
  tar_target(
    model_file,
    save_model(model, "output/model_esm.rds"),
    format = "file"
  ),

  # --- report --------------------------------------------------------------
  # tar_render() detects the tar_read()/tar_load() calls inside the Rmd and
  # re-renders the HTML page only when one of those targets has changed.
  tar_render(report, "esm_depression_trend.Rmd")
)
