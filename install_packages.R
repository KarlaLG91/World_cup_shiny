#!/usr/bin/env Rscript

# Install required packages for World Cup Sweepstake Shiny App
# Run this script: Rscript install_packages.R

# Create user library directory if it doesn't exist
user_lib <- path.expand("~/R/library")
if (!dir.exists(user_lib)) {
  dir.create(user_lib, recursive = TRUE)
  cat("Created user library directory:", user_lib, "\n")
}

# Add user library to search path
if (!user_lib %in% .libPaths()) {
  .libPaths(c(user_lib, .libPaths()))
}

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

cat("Installing packages to:", user_lib, "\n\n")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, lib = user_lib, repos = "https://cran.rstudio.com/")
  } else {
    cat(pkg, "already installed\n")
  }
}

cat("\n✓ All packages installed successfully!\n")
cat("You can now run the Shiny app with: shiny::runApp()\n")
