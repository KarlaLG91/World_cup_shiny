# Data Persistence Functions
# Handles loading and saving app data to CSV files

# Paths for data files
get_data_path <- function(filename) {
  file.path("data", filename)
}

# Load all data from CSV files
load_app_data <- function() {
  list(
    players = load_players(),
    allocations = load_allocations(),
    matches = load_matches(),
    ko_matches = load_ko_matches()
  )
}

# Load players data
load_players <- function() {
  path <- get_data_path("players.csv")
  if (file.exists(path)) {
    df <- read.csv(path, stringsAsFactors = FALSE)
    # Ensure columns exist with correct types
    if (!("id" %in% names(df))) df$id <- seq_len(nrow(df))
    if (!("name" %in% names(df))) df$name <- ""
    if (!("points" %in% names(df))) df$points <- 0
    return(df[, c("id", "name", "points")])
  }
  data.frame(id = integer(), name = character(), points = numeric(), stringsAsFactors = FALSE)
}

# Load allocations data
load_allocations <- function() {
  path <- get_data_path("allocations.csv")
  if (file.exists(path)) {
    df <- read.csv(path, stringsAsFactors = FALSE)
    # Ensure columns exist
    if (!("player_id" %in% names(df))) df$player_id <- integer()
    if (!("player_name" %in% names(df))) df$player_name <- character()
    if (!("country" %in% names(df))) df$country <- character()
    return(df[, c("player_id", "player_name", "country")])
  }
  data.frame(player_id = integer(), player_name = character(), country = character(), 
             stringsAsFactors = FALSE)
}

# Load matches data
load_matches <- function() {
  path <- get_data_path("matches.csv")
  if (file.exists(path)) {
    df <- read.csv(path, stringsAsFactors = FALSE)
    # Ensure columns exist
    if (!("country1" %in% names(df))) df$country1 <- character()
    if (!("goals1" %in% names(df))) df$goals1 <- numeric()
    if (!("country2" %in% names(df))) df$country2 <- character()
    if (!("goals2" %in% names(df))) df$goals2 <- numeric()
    return(df[, c("country1", "goals1", "country2", "goals2")])
  }
  data.frame(country1 = character(), goals1 = numeric(), 
             country2 = character(), goals2 = numeric(), stringsAsFactors = FALSE)
}

# Load knockout matches data
load_ko_matches <- function() {
  path <- get_data_path("ko_matches.csv")
  if (file.exists(path)) {
    df <- read.csv(path, stringsAsFactors = FALSE)
    # Ensure columns exist
    if (!("stage" %in% names(df))) df$stage <- character()
    if (!("match_id" %in% names(df))) df$match_id <- character()
    if (!("team1" %in% names(df))) df$team1 <- character()
    if (!("goals1" %in% names(df))) df$goals1 <- numeric()
    if (!("team2" %in% names(df))) df$team2 <- character()
    if (!("goals2" %in% names(df))) df$goals2 <- numeric()
    if (!("pens1" %in% names(df))) df$pens1 <- NA_real_
    if (!("pens2" %in% names(df))) df$pens2 <- NA_real_
    return(df[, c("stage", "match_id", "team1", "goals1", "team2", "goals2", "pens1", "pens2")])
  }
  data.frame(stage = character(), match_id = character(),
             team1 = character(), goals1 = numeric(),
             team2 = character(), goals2 = numeric(),
             pens1 = numeric(), pens2 = numeric(), stringsAsFactors = FALSE)
}

# Save all data to CSV files
save_app_data <- function(players, allocations, matches, ko_matches) {
  save_players(players)
  save_allocations(allocations)
  save_matches(matches)
  save_ko_matches(ko_matches)
}

# Save players data
save_players <- function(df) {
  path <- get_data_path("players.csv")
  write.csv(df, path, row.names = FALSE)
}

# Save allocations data
save_allocations <- function(df) {
  path <- get_data_path("allocations.csv")
  write.csv(df, path, row.names = FALSE)
}

# Save matches data
save_matches <- function(df) {
  path <- get_data_path("matches.csv")
  write.csv(df, path, row.names = FALSE)
}

# Save knockout matches data
save_ko_matches <- function(df) {
  path <- get_data_path("ko_matches.csv")
  write.csv(df, path, row.names = FALSE)
}
