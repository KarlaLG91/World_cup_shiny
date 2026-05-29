# FIFA World Cup 2026 Sweepstake — Documentation

A Shiny R application to run a World Cup sweepstake: assign countries to players, upload photos, track match results, and export live standings.

---

## Table of Contents

1. [Requirements & Installation](#1-requirements--installation)
2. [After Cloning: Populating Media Files](#2-after-cloning-populating-media-files)
3. [Starting the App](#3-starting-the-app)
4. [Using the App](#4-using-the-app)
   - [Tab 1 — Setup](#tab-1--setup)
   - [Tab 2 — Sweepstake Board](#tab-2--sweepstake-board)
   - [Tab 3 — Results Tracker](#tab-3--results-tracker)
5. [Scoring System](#5-scoring-system)
6. [Saving & Exporting Data](#6-saving--exporting-data)
7. [Country Flags Setup](#7-country-flags-setup)
8. [PDF Report Customization](#8-pdf-report-customization)
9. [Advanced Customization](#9-advanced-customization)
10. [Deployment](#10-deployment)
11. [Project Structure](#11-project-structure)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Requirements & Installation

### Prerequisites

- **R** (version 4.0 or later) — verify with `R --version`

### Install R Packages

Run once before the first launch:

```bash
cd /home/karla/Projects/World_cup_shiny
Rscript install_packages.R
```

Or manually inside an R console:

```r
install.packages(c("shiny", "shinydashboard", "dplyr", "readr", "DT", "png", "grid", "gridExtra"))
```

---

## 2. After Cloning: Populating Media Files

> **Note:** Player photos and country flag images are **not included in the repository**. The directories `www/photos/` and `www/flags/` exist but are empty after cloning. Follow the steps below to populate them before running the app.

### Player Photos (`www/photos/`)

Photos are optional. The app works without them — player names are shown instead.

1. Collect a photo for each player (JPG or PNG, ideally square, ≥ 200 × 200 px, ≤ 5 MB).
2. Rename each photo to match the player's position number as assigned in the app:

   | Player order | Filename  |
   |--------------|-----------|
   | 1st player   | `1.png` or `1.jpg` |
   | 2nd player   | `2.png` or `2.jpg` |
   | …            | …         |

3. Copy the renamed files into `www/photos/`:

   ```bash
   cp your-photo.png www/photos/1.png
   ```

### Country Flag Images (`www/flags/`)

Flags are optional. The app works without them — country names are shown as text instead.

1. Download a PNG flag for each of the 48 World Cup 2026 nations.
2. Name each file using the country name in **lowercase with spaces replaced by underscores**:

   | Country       | Filename              |
   |---------------|-----------------------|
   | Brazil        | `brazil.png`          |
   | United States | `united_states.png`   |
   | Ivory Coast   | `ivory_coast.png`     |

3. Place all flag files in `www/flags/`.

**Recommended sources:**
- [Flag Icons (open-source)](https://github.com/lipis/flag-icons) — ready-to-use PNGs
- [flagcdn.com](https://flagcdn.com) — e.g. `https://flagcdn.com/w160/br.png`
- [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Flags_of_countries)

**Bulk download script** — edit the country-to-code mapping and run once:

```r
# Run from the project root: Rscript download_flags.R
countries <- c(
  brazil = "br", france = "fr", england = "gb-eng",
  germany = "de", spain = "es", argentina = "ar",
  portugal = "pt", netherlands = "nl", belgium = "be",
  united_states = "us", mexico = "mx", canada = "ca"
  # add all 48 nations...
)

dir.create("www/flags", showWarnings = FALSE)
for (name in names(countries)) {
  url  <- paste0("https://flagcdn.com/w160/", countries[[name]], ".png")
  dest <- paste0("www/flags/", name, ".png")
  tryCatch(
    download.file(url, dest, mode = "wb", quiet = TRUE),
    error = function(e) message("Failed: ", name)
  )
}
```

```bash
Rscript download_flags.R
```

---

## 3. Starting the App

Choose whichever method suits you:

**Option A — Bash script (recommended)**

```bash
cd /home/karla/Projects/World_cup_shiny
bash start_app.sh
```

The script checks whether R is installed, installs packages if needed, and opens the browser automatically.

**Option B — R console**

```r
setwd("/home/karla/Projects/World_cup_shiny")
shiny::runApp()
```

**Option C — RStudio**

Open `app.R` and click the green **Run App** button.

The app opens in your browser at `http://localhost:3838` by default.

---

## 4. Using the App

The app has three tabs. Work through Tab 1 once at the start of the tournament, then use Tabs 2 and 3 throughout.

---

### Tab 1 — Setup

Everything needed before the tournament starts is in one place, organised as three numbered steps.

#### Step 1 — Players

1. Enter one name per line in the text box:

   ```
   Alice
   Bob
   Charlie
   Diana
   ```

2. Click **Save Players**. The player list appears in the table immediately.
3. *(Optional)* Click **Export CSV** to save the list, or **Clear All** to reset all data.

**Notes:**

- Between 1 and 48 participants are supported.
- Re-submitting names resets all allocations and match results.

#### Step 2 — Player Photos

> **Photos are not included in the repository.** See [After Cloning: Populating Media Files](#2-after-cloning-populating-media-files) for how to add them.

Optional — upload a photo for each player to display on the Sweepstake Board.

1. For each player, click **Choose File** and select a JPG or PNG image.
2. Click **Save Photos** when done.

**Photo requirements:**

- Format: JPG or PNG
- Recommended size: 200 × 200 px or larger (square works best)
- Max file size: 5 MB per photo

#### Step 3 — Country Allocation

Distribute all 48 FIFA World Cup 2026 nations across players using a ranked allocation.

1. A status message confirms how many players are ready and how many countries each will receive.
2. Click **Allocate Countries**.
3. Every country is assigned — none left out, none duplicated.
4. Each player is guaranteed **at least one top-ranked country**.
5. The full allocation appears in a scrollable table below the button.

**How the allocation works:**

Countries are dealt in two rounds:

- **Round 1 (guaranteed top team):** The 12 highest-ranked countries (Spain, Argentina, France, England, Brazil, Portugal, Netherlands, Belgium, Germany, United States, Mexico, Canada) are shuffled and one is dealt to each player. With more than 12 players, the 13th player onwards receives the next best country by FIFA ranking instead.
- **Round 2 (remainder):** The remaining countries are shuffled and dealt round-robin.

Each player receives `floor(48/n)` or `ceil(48/n)` countries. Click **Allocate Countries** again at any time to re-randomise.

---

### Tab 2 — Sweepstake Board

A visual overview of the full sweepstake — designed to be left on a shared screen during the tournament.

At the top, three status tiles show at a glance:

- Number of players
- Countries allocated (green once done)
- Matches recorded

Each player card shows:

- Photo (if uploaded)
- Player name
- All assigned country flags and names
- Current points total

Cards update automatically as you record results in Tab 3.

---

### Tab 3 — Results Tracker

Record match results and view live standings.

The same three status tiles appear at the top for quick reference.

**To record a result:**

1. Select **Country 1** from the left dropdown.
2. Enter goals scored by Country 1.
3. Enter goals scored by Country 2.
4. Select **Country 2** from the right dropdown.
5. Click **Record Result**.

The **Live Standings** table updates immediately with rank, player name, and points.

**Example:**

```
Match: Brazil 2–1 Mexico
→ Alice (Brazil) receives 3 points
→ Bob (Mexico) receives 0 points
```

**Exporting:**
- **Standings CSV** — downloads the current standings table.
- **Results PDF** — generates a formatted PDF report.

---

## 5. Scoring System

| Result | Points |
|--------|--------|
| Win    | 3      |
| Draw   | 1      |
| Loss   | 0      |

Points are awarded only to the player whose country is playing in the recorded match.

---

## 6. Saving & Exporting Data

Player data and match results are held in memory and are lost when the app is closed. To preserve data:

- **Export player list**: Setup tab (Step 1) → **Export CSV** → saves players and their points.
- **Export standings**: Results Tracker tab → **Standings CSV** or **Results PDF**.

To restore after a restart, re-enter the player names from your saved CSV, re-run country allocation, and re-enter match results.

---

## 7. Country Flags Setup

> **Flag images are not included in the repository.** See [After Cloning: Populating Media Files](#2-after-cloning-populating-media-files) for how to add them.

Flag images are optional — the app works without them (country names are shown as text instead).

### File naming convention

Place PNG files in `www/flags/`. Filenames must be the country name in lowercase with spaces replaced by underscores:

| Country        | Filename              |
|----------------|-----------------------|
| Brazil         | `brazil.png`          |
| United States  | `united_states.png`   |
| Ivory Coast    | `ivory_coast.png`     |
| Saudi Arabia   | `saudi_arabia.png`    |
| South Korea    | `south_korea.png`     |

### Recommended image specs

- Format: PNG (transparent background preferred)
- Size: 100 × 60 px
- Max file size: < 50 KB per flag

### Where to get flags

- **Flag Icons** (open-source): https://github.com/lipis/flag-icons
- **Wikipedia Commons**: https://commons.wikimedia.org/wiki/Category:Flags_of_countries — search by country and download the PNG version.

### World Cup 2026 — all 48 nations (by group)

| Group | Teams |
| ----- | ----- |
| A | Mexico, South Africa, South Korea, Czech Republic |
| B | Canada, Bosnia and Herzegovina, Qatar, Switzerland |
| C | Brazil, Morocco, Haiti, Scotland |
| D | United States, Paraguay, Australia, Turkey |
| E | Germany, Curaçao, Ivory Coast, Ecuador |
| F | Netherlands, Japan, Sweden, Tunisia |
| G | Belgium, Egypt, Iran, New Zealand |
| H | Spain, Cape Verde, Saudi Arabia, Uruguay |
| I | France, Senegal, Iraq, Norway |
| J | Argentina, Algeria, Austria, Jordan |
| K | Portugal, DR Congo, Uzbekistan, Colombia |
| L | England, Croatia, Ghana, Panama |

---

## 8. PDF Report Customization

The Results Tracker tab exports a PDF via `R/pdf_export.R` → `generate_pdf_report()`.

### Change the report title

```r
# R/pdf_export.R — inside generate_pdf_report()
title_grob <- textGrob(
  "Your Custom Title Here",          # ← edit this
  gp = gpar(fontsize = 20, fontface = "bold"),
  just = "center"
)
```

### Change font sizes

```r
gpar(fontsize = 20, ...)             # title size
ttheme_default(base_size = 10)       # table size
```

### Add a subtitle

```r
subtitle_grob <- textGrob(
  "Tournament — June 2026",
  gp = gpar(fontsize = 12),
  just = "center"
)

grid.arrange(title_grob, subtitle_grob, standings_grob,
             ncol = 1, heights = c(0.08, 0.05, 0.87))
```

### Change table columns

```r
standings[, c("position", "name", "country", "points")]
# Add extra columns as needed
```

---

## 9. Advanced Customization

### Custom scoring rules

Edit `R/scoring.R` → `update_player_points()` to add knockout-stage multipliers, goal-difference bonuses, clean-sheet points, etc.:

```r
if (tournament_stage == "Final") {
  points_multiplier <- 2
}
```

### Export to Excel

```r
install.packages("writexl")
# In app.R — add to Results tab:
downloadButton("export_xlsx", "Export to Excel")
```

### Persistent data storage

Replace in-memory reactive values with a database:

```r
# SQLite
install.packages("RSQLite")

# PostgreSQL
install.packages("RPostgreSQL")
```

### Performance: caching

```r
memoise::memoise(calculate_standings)
```

### Mobile-friendly UI

```r
install.packages("shinyMobile")
# Wrap UI with mobileApp()
```

---

## 10. Deployment

### Local network (all devices on the same Wi-Fi)

```bash
R -e "shiny::runApp(host='0.0.0.0', port=3838)"
```

Other users access the app at `http://<your-ip>:3838`.

### Shiny Server (Linux)

```bash
# After installing Shiny Server, copy files to:
/srv/shiny-server/worldcup/
```

### Docker

```dockerfile
FROM r-base:latest
RUN Rscript -e "install.packages(c('shiny','shinydashboard','dplyr','readr','DT','png','grid','gridExtra'))"
COPY . /app
WORKDIR /app
EXPOSE 3838
CMD ["R", "-e", "shiny::runApp(host='0.0.0.0', port=3838)"]
```

### Cloud (shinyapps.io)

```r
install.packages("rsconnect")
rsconnect::deployApp("/home/karla/Projects/World_cup_shiny")
```

---

## 11. Project Structure

```
World_cup_shiny/
├── app.R                  # Main Shiny app (UI + server)
├── install_packages.R     # One-time package installer
├── start_app.sh           # Launch script
├── config.yaml            # Configuration settings
│
├── R/
│   ├── helpers.R          # Utility functions (country list, validation)
│   ├── country_allocation.R  # Random country assignment logic
│   ├── photo_management.R    # Photo upload & file handling
│   ├── scoring.R          # Points calculation
│   └── pdf_export.R       # PDF/HTML report generation
│
├── www/
│   ├── photos/            # Player photos — NOT in repo, add manually (see §2)
│   └── flags/             # Country flag PNGs — NOT in repo, add manually (see §2)
│
├── data/
│   └── sample_players.csv # Example player data
│
└── exports/               # Generated reports (auto-created at runtime)
    ├── players.csv
    ├── results.pdf
    └── results.html
```

**Key files to edit for common changes:**

| Goal | File |
| ------ | ------ |
| Change scoring rules | `R/scoring.R` |
| Customise PDF layout | `R/pdf_export.R` |
| Add/remove app tabs | `app.R` |
| Modify UI colours/theme | `app.R` (dashboardPage section) |
| Change country groups | `R/helpers.R` → `get_world_cup_countries()` |
| Change allocation ranking | `R/helpers.R` → `get_ranked_countries()` |

---

## 12. Troubleshooting

| Problem | Solution |
| --------- | ---------- |
| App won't start | Run `Rscript install_packages.R`; verify `R --version` works |
| Port already in use | `R -e "shiny::runApp(port=3839)"` |
| Photos not showing | Confirm files are in `www/photos/` named `1.jpg`, `2.jpg`, etc. |
| Flags not showing | Check filename matches country name (lowercase, underscores); confirm PNG is valid |
| Countries not allocated | You must have at least 1 player entered first |
| Data lost after restart | Always export the player list CSV before closing the app |
| R packages missing | `install.packages("shiny", dependencies = TRUE)` — repeat for each package |
| Wrong flags displayed | Verify the filename matches the exact country name used by the app |
