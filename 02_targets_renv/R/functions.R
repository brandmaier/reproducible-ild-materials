# R/functions.R
# Functions used by the targets pipeline in _targets.R.
# Each function does one step and has no side effects (except the two
# save_*() helpers, which return the path of the file they wrote).

# --- file loading ------------------------------------------------------------

#' Read the raw ESM data from the csv file
read_esm <- function(path) {
  read.csv(path)
}

# --- preprocessing -------------------------------------------------------------

#' Parse dates, sort by date and beep number, add a day counter starting at zero
preprocess_esm <- function(raw) {
  raw$date <- as.Date(raw$date, format = "%d/%m/%y")
  stopifnot(!anyNA(raw$date))                      # fail early on parsing errors

  raw <- raw[order(raw$date, raw$beepno), ]        # "first" = earliest beep
  raw$day <- as.numeric(raw$date - min(raw$date))  # starts at zero
  raw
}

#' Beep-level series: carry the weekly depression rating forward (for plotting)
make_beeps <- function(esm) {
  tidyr::fill(esm, dep, .direction = "down")
}

#' Weekly series: one row per actual weekly assessment.
#' Must be derived from the *unfilled* data (see make_beeps()).
make_weekly <- function(esm) {
  esm |>
    dplyr::filter(!is.na(dep)) |>
    dplyr::distinct(date, dep, .keep_all = TRUE) |>
    dplyr::mutate(week = floor(day / 7) + 1)
}

# --- plotting ------------------------------------------------------------------

#' Recreate the SCL-90-R depression panel of Figure 1a in
#' Kossakowski et al. (2017; doi: 10.5334/jopd.29).
#' The dashed line is the linear trend of the weekly ratings.
make_depression_plot <- function(beeps, weekly) {
  ggplot2::ggplot(beeps, ggplot2::aes(x = date, y = dep)) +
    ggplot2::geom_line(linewidth = 2, color = "#0171b6") +
    ggplot2::geom_smooth(
      data = weekly, method = "lm", formula = y ~ x,
      color = "darkblue", linetype = "dashed", se = FALSE
    ) +
    ggplot2::scale_y_continuous(breaks = scales::breaks_width(0.2)) +
    ggplot2::coord_cartesian(ylim = c(1, 2.8)) +
    ggplot2::labs(
      title = "SCL-90-R depression subscale",
      x = "Date",
      y = "Average item score"
    ) +
    ggplot2::theme_classic() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_line(color = "grey80", linewidth = 0.5),
      panel.grid.minor.y = ggplot2::element_blank()
    )
}

#' Save a plot to disk and return the path (needed for format = "file" targets)
save_plot <- function(plot, path, width = 8, height = 4) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(path, plot, width = width, height = height)
  path
}

# --- modeling ------------------------------------------------------------------

#' Linear time trend of the weekly depression ratings (all study phases pooled)
fit_trend_model <- function(weekly) {
  lm(dep ~ week, data = weekly)
}

#' Save a fitted model to disk and return the path
save_model <- function(model, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  saveRDS(model, path)
  path
}
