# setup_repro.R
#
# One-time setup of the container + Make infrastructure with the repro package.
# Run interactively from the project root (the folder that contains
# esm_depression_trend.Rmd). Afterwards, reproduction needs only `make` and
# Docker; the repro package is not required on the reproducing machine.

install.packages("repro",
                 repos = c("https://aaronpeikert.r-universe.dev",
                           "https://cloud.r-project.org"))
library(repro)

# are git, make and docker available? (offers help if not)
check_git()
check_make()
check_docker()

# --- project skeleton ---------------------------------------------------------
# The .Rproj file and the git repo mark the project root, which
# repro::automate_load_*() use (via usethis::proj_path()) to find the script and
# data -- also inside the container.
usethis::use_rstudio()
usethis::use_git()
usethis::use_git_ignore(c("output/", ".Rproj.user", ".Rhistory", ".RData"))

# --- pin the R version of the base image ---------------------------------------
# automate() creates the base image definition itself if none exists (using the
# current R version). Creating it first makes the pin explicit and reviewable.
fs::dir_create(".repro")
use_docker(
  rver  = paste(R.version$major, R.version$minor, sep = "."),
  stack = "verse",                       # rocker/verse: tidyverse + pandoc + LaTeX
  file  = ".repro/Dockerfile_base",
  open  = FALSE
)

# --- generate everything from the YAML header of the Rmd ------------------------
# Order matters: the Dockerfile must exist before the GitHub workflows are added,
# and the Makefile (created last) includes the publish Makefile if it exists.
automate_docker()    # Dockerfile  <- `repro: packages:` (+ optional `apt:`)
automate_publish()   # GitHub Actions (image build + gh-pages publish), optional
automate()           # Makefile    <- `repro: data/scripts:` + output format

# --- manual step ----------------------------------------------------------------
# Open the generated Makefile and declare the default and publish targets:
#
#   all: esm_depression_trend.html
#   publish/: esm_depression_trend.html
#
# automate() prints a to-do message with the exact lines to add.

# --- test it ----------------------------------------------------------------------
# In a terminal:
#   make docker             # build the image
#   make all DOCKER=TRUE    # render the report inside the container
#
# repro::reproduce() prints the command a newcomer should use.
