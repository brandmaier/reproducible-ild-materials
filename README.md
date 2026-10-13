# Reproducible analysis of intensive longitudinal data: three approaches

This repository contains **three variants of the same analysis**. Each variant
demonstrates different reproducibility approaches presented in the book chapter

> Brandmaier, A. M. (in press). Towards reproducible data analysis of intensive
> longitudinal data in R. In T. Koch, T. Lischetzke, & J. Holtmann (Eds.),
> *Handbook of intensive longitudinal data analysis*. Routledge.

The analysis itself is deliberately simple. What differs between the demos is
*how* the workflow is organized, documented, and made reproducible.

| Demo | Folder | Approach | What you need to reproduce it |
|---|---|---|---|
| 01 | `demo01_reproducibleRchunks/` | An R Markdown document with reproducible R chunks that provide automated reproducibility checks | R, RStudio (optional) |
| 02 | `demo02_targets_renv/` | An R Markdown file that only shows the results; all computations are handled in a [`targets`](https://docs.ropensci.org/targets/) pipeline, packages are managed via `renv` | R |
| 03 | `demo03_repro/` | The [`repro`](https://github.com/aaronpeikert/repro) package approach: dependencies are managed through `repro` metadata, and the entire analysis runs inside a container | `make` and Docker (R is not needed) |

## The analysis

We use data from a single-case experience-sampling study in which a participant
monitored his momentary experiences while gradually discontinuing his
antidepressant medication. In addition to the momentary ratings, depressive
symptoms were assessed **weekly** with the depression subscale of the SCL-90-R.

All three demos

1. recreate the depression panel (SCL-90-R depression subscale, average item
   score over time) of Figure 1a in Kossakowski et al. (2017),
2. fit a linear model that estimates the linear time trend of the weekly
   depression ratings, and
3. report the model statistics with the [`cocoon`](#software) package, so that
   numbers in the text are generated directly from the fitted model and cannot
   drift out of sync with the analysis.

> **Note.** The study consists of several phases (e.g., baseline, dose
> reduction, post-discontinuation), which are *not* modeled here. A single linear
> trend is a coarse summary, and the analysis serves only to illustrate the
> workflows. We draw no substantive conclusions.

## The dataset

Kossakowski, J. J., Groot, P. C., Haslbeck, J. M. B., Borsboom, D., & Wichers,
M. (2017). Data from "Critical slowing down as a personalized early warning
signal for depression". *Journal of Open Psychology Data, 5*(1).
https://doi.org/10.5334/jopd.29

- OSF repository: <https://osf.io/j4fg8>
- License: CC BY 4.0
- Design: N = 1 (male, aged 57, history of multiple episodes of major
  depression, previously on antidepressants for 8.5 years), about 10 beeps per
  day over 239 days (roughly 1,470 momentary observations, 50 items), plus
  weekly SCL-90-R depression assessments.

The data are redistributed here under their original license. 
You can also download the file from OSF and place it
at `data/ESMdata.csv` inside each demo folder.

## Approach 1: R Markdown with reproducible R chunks and automated checks

The approach shown in `01_reproducibleRchunks/` has a single R Markdown document that contains the complete analysis:
data loading, preprocessing, plotting, modeling, and reporting in separate
R chunks. The R chunks are written so that they run top to bottom on a 
fresh session, and some include automated checks (e.g., assertions on the 
data and modeling results) that make it visible when a result can no longer be
reproduced.

To rebuild, run:

```r
rmarkdown::render("01_reproducibleRchunks/esm_depression_trend.Rmd")
```

## Demo 02: R Markdown for results only, computations in a targets pipeline

The approach presented in `02_targets_renv/` separates computation from reporting. All steps (file loading,
preprocessing, plotting, modeling) are **targets** in `_targets.R`, implemented
as functions in `R/functions.R`. The R Markdown file only *reads* the stored
results via `tar_read()`/`tar_load()` and formats them. Because `targets` tracks
the dependencies between steps, only outdated steps are re-run, and the HTML
report is rebuilt when one of its inputs changes. The `renv` package can be used
to recreate specified versions of the R packages used.

To rebuild:

```r
setwd("02_targets_renv")
renv::restore()       # [optional] recreate the R package version using renv
targets::tar_make()   # builds the entire pipeline, including the HTML report
```

## Demo 03: the repro package, with a container

The project `03_repro/` keeps the analysis code in `R/analysis.R` and the narrative in an R
Markdown file. The YAML header of the R Markdown file declares the **packages**
(GitHub packages pinned to a commit), the **script**, and the **data** file.
`repro::automate()` generates a `Dockerfile` and a `Makefile` from this metadata
(see `setup_repro.R`), so the whole analysis runs inside a container with a fixed
R version and fixed package versions. Reproducing it requires only `make` and
Docker:

```bash
cd 03_repro
make docker            # build the image once
make all DOCKER=TRUE   # render the report inside the container
```

**Note**: On Windows, this requires to adapt a PATH variable in the Makefile manually

If no docker environment is available, the document can be build in the local
R environment -- required packages need to be installed manually then:

```bash
make all
```


## Software

| | Approach 1 | Approach 2 | Approach 3 |
|---|---|---|---|
| R packages | tidyr, dplyr, ggplot2, cocoon | + targets, tarchetypes, renv | tidyr, dplyr, ggplot2, cocoon, repro (installed in the container) |
| Environment | local R | local R | Docker image (`rocker/verse`, pinned R version) |
| Entry point | `rmarkdown::render()` | `targets::tar_make()` | `make all DOCKER=TRUE` |

The package versions used for a run are printed in the *Session information*
section at the end of each report.

## Repository structure

```
.
├── README.md
├── 01_reproducibleRchunks/    # R Markdown document with reproducible chunks and checks
├── 02_targets_renv/    # targets pipeline + results-only R Markdown report
└── 03_repro/    # repro package metadata + Dockerfile/Makefile
```

## License and citation

- **Code** (R scripts, R Markdown source files, `_targets.R`, `Makefile`s,
  `Dockerfile`s, and setup scripts) is licensed under the
  [MIT License](https://opensource.org/license/mit).
- **All generated materials** (rendered reports, figures, and other outputs
  produced by running the code) are licensed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- The **dataset** is not part of this repository. It is licensed under CC BY 4.0
  by its authors; please cite Kossakowski et al. (2017) when reusing it.

If you use these materials, please also cite the book chapter listed at the top
of this README.

## Author

Andreas M. Brandmaier
