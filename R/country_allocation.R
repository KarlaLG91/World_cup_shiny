# Country allocation functions

#' Distribute all 48 World Cup countries across players with stratified allocation.
#'
#' Each player is guaranteed exactly one "top-tier" country:
#'   - With <= 12 players: everyone gets one of the 12 premium teams
#'     (Spain, Argentina, France, England, Brazil, Portugal, Netherlands,
#'      Belgium, Germany, United States, Mexico, Canada).
#'   - With 13-48 players: the 13th+ player receives the next highest-ranked
#'     country by FIFA ranking instead.
#' Remaining countries are shuffled randomly and distributed round-robin.
#'
#' Returns a data.frame with columns: player_id, player_name, country.
allocate_countries_randomly <- function(player_names) {
  all_ranked <- get_ranked_countries()   # 48 countries, top-tier first then by rank
  n_players  <- length(player_names)
  if (n_players == 0) stop("No players provided")

  # First-round pool: exactly one guaranteed "prestige" country per player
  first_round <- all_ranked[seq_len(n_players)]
  # Second-round pool: the remaining countries (empty when n_players == 48)
  second_round <- all_ranked[-seq_len(n_players)]

  # Shuffle first-round and assign one per player
  top_alloc <- data.frame(
    player_id   = seq_len(n_players),
    player_name = player_names,
    country     = sample(first_round),
    stringsAsFactors = FALSE
  )

  if (length(second_round) == 0) return(top_alloc)

  # Shuffle remainder and deal round-robin
  shuffled_rest <- sample(second_round)
  rest_indices  <- ((seq_along(shuffled_rest) - 1) %% n_players) + 1
  rest_alloc <- data.frame(
    player_id   = rest_indices,
    player_name = player_names[rest_indices],
    country     = shuffled_rest,
    stringsAsFactors = FALSE
  )

  rbind(top_alloc, rest_alloc)
}

#' Get World Cup 2026 groups (draw held December 5, 2025)
get_world_cup_groups <- function() {
  list(
    "A" = c("Mexico", "South Africa", "South Korea", "Czech Republic"),
    "B" = c("Canada", "Bosnia and Herzegovina", "Qatar", "Switzerland"),
    "C" = c("Brazil", "Morocco", "Haiti", "Scotland"),
    "D" = c("United States", "Paraguay", "Australia", "Turkey"),
    "E" = c("Germany", "Curaçao", "Ivory Coast", "Ecuador"),
    "F" = c("Netherlands", "Japan", "Sweden", "Tunisia"),
    "G" = c("Belgium", "Egypt", "Iran", "New Zealand"),
    "H" = c("Spain", "Cape Verde", "Saudi Arabia", "Uruguay"),
    "I" = c("France", "Senegal", "Iraq", "Norway"),
    "J" = c("Argentina", "Algeria", "Austria", "Jordan"),
    "K" = c("Portugal", "DR Congo", "Uzbekistan", "Colombia"),
    "L" = c("England", "Croatia", "Ghana", "Panama")
  )
}

#' Get group for a country
get_country_group <- function(country) {
  groups <- get_world_cup_groups()
  for (group_name in names(groups)) {
    if (country %in% groups[[group_name]]) {
      return(group_name)
    }
  }
  return(NA_character_)
}
