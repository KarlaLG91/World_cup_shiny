#!/usr/bin/env Rscript

# Install required packages for World Cup Sweepstake Shiny App
# Run this script: Rscript install_packages.R

packages <- c(
  "shiny",
  "shinydashboard",
  "dplyr",
  "readr",
  "DT",
  "png",
  "grid",
  "gridExtra"
)

cat("Installing required packages...\n")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg)
  } else {
    cat(pkg, "already installed\n")
  }
}

cat("\n✓ All packages installed successfully!\n")
cat("You can now run the Shiny app with: shiny::runApp()\n")
