#!/usr/bin/env Rscript

# Download flag images for all World Cup 2026 countries
# Flags are downloaded from a free flag API and saved to www/flags/

library(httr)
library(png)

# Create flags directory if it doesn't exist
flags_dir <- "www/flags"
if (!dir.exists(flags_dir)) {
  dir.create(flags_dir, recursive = TRUE)
  cat("Created directory:", flags_dir, "\n")
}

# World Cup 2026 countries (48 teams) - matches helpers.R get_world_cup_countries()
countries <- c(
  # Group A
  "Mexico", "South Africa", "South Korea", "Czech Republic",
  # Group B
  "Canada", "Bosnia and Herzegovina", "Qatar", "Switzerland",
  # Group C
  "Brazil", "Morocco", "Haiti", "Scotland",
  # Group D
  "United States", "Paraguay", "Australia", "Turkey",
  # Group E
  "Germany", "Curaçao", "Ivory Coast", "Ecuador",
  # Group F
  "Netherlands", "Japan", "Sweden", "Tunisia",
  # Group G
  "Belgium", "Egypt", "Iran", "New Zealand",
  # Group H
  "Spain", "Cape Verde", "Saudi Arabia", "Uruguay",
  # Group I
  "France", "Senegal", "Iraq", "Norway",
  # Group J
  "Argentina", "Algeria", "Austria", "Jordan",
  # Group K
  "Portugal", "DR Congo", "Uzbekistan", "Colombia",
  # Group L
  "England", "Croatia", "Ghana", "Panama"
)

# Flag emoji codes for countries (country name -> flag code)
flag_codes <- c(
  # Group A
  "Mexico" = "MX", "South Africa" = "ZA", "South Korea" = "KR", "Czech Republic" = "CZ",
  # Group B
  "Canada" = "CA", "Bosnia and Herzegovina" = "BA", "Qatar" = "QA", "Switzerland" = "CH",
  # Group C
  "Brazil" = "BR", "Morocco" = "MA", "Haiti" = "HT", "Scotland" = "GB-SCT",
  # Group D
  "United States" = "US", "Paraguay" = "PY", "Australia" = "AU", "Turkey" = "TR",
  # Group E
  "Germany" = "DE", "Curaçao" = "CW", "Ivory Coast" = "CI", "Ecuador" = "EC",
  # Group F
  "Netherlands" = "NL", "Japan" = "JP", "Sweden" = "SE", "Tunisia" = "TN",
  # Group G
  "Belgium" = "BE", "Egypt" = "EG", "Iran" = "IR", "New Zealand" = "NZ",
  # Group H
  "Spain" = "ES", "Cape Verde" = "CV", "Saudi Arabia" = "SA", "Uruguay" = "UY",
  # Group I
  "France" = "FR", "Senegal" = "SN", "Iraq" = "IQ", "Norway" = "NO",
  # Group J
  "Argentina" = "AR", "Algeria" = "DZ", "Austria" = "AT", "Jordan" = "JO",
  # Group K
  "Portugal" = "PT", "DR Congo" = "CD", "Uzbekistan" = "UZ", "Colombia" = "CO",
  # Group L
  "England" = "GB-ENG", "Croatia" = "HR", "Ghana" = "GH", "Panama" = "PA"
)

# Download flag for each country
cat("\nDownloading flags...\n")
success_count <- 0
failed_count <- 0

for (i in seq_along(countries)) {
  country <- countries[i]
  code <- flag_codes[country]
  
  if (is.na(code)) {
    cat("⚠ No flag code for:", country, "\n")
    failed_count <- failed_count + 1
    next
  }
  
  # Filename (convert country name to lowercase with underscores)
  filename <- tolower(gsub(" ", "_", country))
  filepath <- file.path(flags_dir, paste0(filename, ".png"))
  
  # Skip if already exists
  if (file.exists(filepath)) {
    cat("✓", country, "- already exists\n")
    success_count <- success_count + 1
    next
  }
  
  # Use flagcdn.com API (free, no key required)
  url <- paste0("https://flagcdn.com/w160/", tolower(code), ".png")
  
  tryCatch({
    response <- GET(url, timeout(10))
    
    if (status_code(response) == 200) {
      # Save the PNG file
      writeBin(content(response, "raw"), filepath)
      cat("✓", country, "(", code, ")\n")
      success_count <- success_count + 1
    } else {
      cat("✗", country, "- HTTP", status_code(response), "\n")
      failed_count <- failed_count + 1
    }
  }, error = function(e) {
    cat("✗", country, "- Error:", conditionMessage(e), "\n")
    failed_count <<- failed_count + 1
  })
  
  # Rate limiting - 0.5 second delay between requests
  Sys.sleep(0.5)
}

cat("\n")
cat("Downloaded:", success_count, "flags\n")
cat("Failed:", failed_count, "flags\n")
cat("Total:", success_count + failed_count, "/ 48 countries\n")
cat("\n✓ Flag download complete!\n")
