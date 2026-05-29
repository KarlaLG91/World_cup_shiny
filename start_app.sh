#!/bin/bash

# Startup script for World Cup Sweepstake Shiny App

echo "=========================================="
echo "FIFA World Cup 2026 Sweepstake"
echo "Shiny Application Launcher"
echo "=========================================="
echo ""

# Check if R is installed
if ! command -v Rscript &> /dev/null
then
    echo "ERROR: R is not installed or not in PATH"
    echo "Please install R from https://www.r-project.org/"
    exit 1
fi

echo "✓ R found"
echo ""

# Install packages
echo "Checking and installing required packages..."
Rscript install_packages.R

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install packages"
    exit 1
fi

echo ""
echo "=========================================="
echo "Starting Shiny Application..."
echo "=========================================="
echo "Opening app in browser at http://localhost:3838"
echo "Press Ctrl+C to stop the server"
echo "=========================================="
echo ""

# Start the app
R -e "shiny::runApp()"
