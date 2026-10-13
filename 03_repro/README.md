# Reproducible analysis of an intensive longitudinal depression time series

Open Materials for Brandmaier (in press), *Towards reproducible data analysis of
intensive longitudinal data in R*. Data: Kossakowski et al. (2017),
doi:10.5334/jopd.29 (CC BY 4.0).

## Reproduce the report

Requirements: `git`, `make`, and Docker. R is **not** needed.

```
git clone <this repository>
cd <this repository>
# place the data file at data/ESMdata.csv (see https://osf.io/j4fg8)
make docker            # build the image
make all DOCKER=TRUE   # render esm_depression_trend.html inside the container
```

## Files

| File | Purpose |
|---|---|
| `esm_depression_trend.Rmd` | Report; the `repro:` YAML block declares packages, script, data |
| `R/analysis.R` | The analysis code, in named chunks pulled into the report |
| `setup_repro.R` | One-time script that generated the files below with `repro` |
| `Dockerfile`, `.repro/` | Container definition (generated; edit `.repro/Dockerfile_manual`) |
| `Makefile`, `.repro/Makefile_*` | Build recipe (generated) |
| `output/` | Saved model and figure (not tracked) |
