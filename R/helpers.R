# Helper functions for World Cup Sweepstake

#' Get World Cup 2026 Countries
#' Returns all 48 teams organised by their actual group (draw held December 5, 2025).
get_world_cup_countries <- function() {
  c(
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
}

#' Get all 48 countries sorted for stratified allocation.
#' The first 12 are the user-defined "premium" tier (guaranteed 1 per player).
#' The remaining 36 follow FIFA ranking order (November 2025 draw ranking).
get_ranked_countries <- function() {
  c(
    # --- Premium tier (12): guaranteed one per player ---
    "Spain", "Argentina", "France", "England", "Brazil", "Portugal",
    "Netherlands", "Belgium", "Germany", "United States", "Mexico", "Canada",
    # --- Ranked remainder (36) by FIFA ranking ---
    "Croatia", "Morocco", "Colombia", "Uruguay", "Switzerland",
    "Japan", "Senegal", "Iran", "South Korea", "Ecuador", "Austria",
    "Australia", "Norway", "Panama", "Sweden", "Egypt", "Algeria",
    "Scotland", "Turkey", "Paraguay", "Tunisia", "Ivory Coast",
    "Czech Republic", "Uzbekistan", "Qatar", "Ghana", "Saudi Arabia",
    "Cape Verde", "Bosnia and Herzegovina", "South Africa", "Iraq",
    "DR Congo", "New Zealand", "Jordan", "Cura\u00e7ao", "Haiti"
  )
}

#' Validate Player Names
validate_player_names <- function(names) {
  names <- trimws(names)
  names <- names[names != ""]
  
  if (length(names) == 0) {
    return(list(valid = FALSE, message = "No player names provided"))
  }
  
  if (length(names) > 48) {
    return(list(valid = FALSE, message = "Too many players (max 48)"))
  }
  
  if (length(unique(names)) != length(names)) {
    return(list(valid = FALSE, message = "Duplicate player names found"))
  }
  
  return(list(valid = TRUE, message = "Valid player list", count = length(names)))
}

#' Calculate standings for a single group from recorded match results.
#' Only counts matches where BOTH teams are in the supplied group.
#' Returns a data.frame sorted by Pts desc, GD desc, GF desc.
calculate_group_standings <- function(group_countries, matches_df) {
  standings <- data.frame(
    Team = group_countries,
    P = 0L, W = 0L, D = 0L, L = 0L,
    GF = 0L, GA = 0L, GD = 0L, Pts = 0L,
    stringsAsFactors = FALSE
  )

  if (nrow(matches_df) == 0) return(standings)

  for (i in seq_len(nrow(matches_df))) {
    c1 <- matches_df$country1[i]; c2 <- matches_df$country2[i]
    g1 <- matches_df$goals1[i];   g2 <- matches_df$goals2[i]
    if (!(c1 %in% group_countries) || !(c2 %in% group_countries)) next

    i1 <- which(standings$Team == c1); i2 <- which(standings$Team == c2)
    standings$P[i1]  <- standings$P[i1]  + 1L
    standings$P[i2]  <- standings$P[i2]  + 1L
    standings$GF[i1] <- standings$GF[i1] + g1
    standings$GA[i1] <- standings$GA[i1] + g2
    standings$GF[i2] <- standings$GF[i2] + g2
    standings$GA[i2] <- standings$GA[i2] + g1

    if (g1 > g2) {
      standings$W[i1] <- standings$W[i1] + 1L; standings$L[i2] <- standings$L[i2] + 1L
      standings$Pts[i1] <- standings$Pts[i1] + 3L
    } else if (g1 < g2) {
      standings$W[i2] <- standings$W[i2] + 1L; standings$L[i1] <- standings$L[i1] + 1L
      standings$Pts[i2] <- standings$Pts[i2] + 3L
    } else {
      standings$D[i1] <- standings$D[i1] + 1L; standings$D[i2] <- standings$D[i2] + 1L
      standings$Pts[i1] <- standings$Pts[i1] + 1L; standings$Pts[i2] <- standings$Pts[i2] + 1L
    }
  }

  standings$GD <- standings$GF - standings$GA
  standings[order(-standings$Pts, -standings$GD, -standings$GF), ]
}

#' Return a character vector of country names that are eliminated from the tournament.
#'
#' A country is eliminated when any of the following is true:
#'   - It finished 4th in its group (once all 6 group-stage matches are played).
#'   - It finished 3rd in its group but knockout_slots is populated and the team
#'     is not listed there (i.e., it didn't qualify as a best third-place team).
#'   - It lost in a knockout round match (including 3rd-place play-off).
get_eliminated_countries <- function(groups, matches_df, ko_matches_df, knockout_slots) {
  eliminated <- character(0)

  # --- Group-stage eliminations ---
  for (grp in names(groups)) {
    teams      <- groups[[grp]]
    grp_played <- if (is.null(matches_df) || nrow(matches_df) == 0L) 0L else
      sum(matches_df$country1 %in% teams & matches_df$country2 %in% teams)
    if (grp_played < 6L) next  # group not yet complete

    standing <- calculate_group_standings(teams, matches_df)

    # 4th place is always eliminated
    if (nrow(standing) >= 4L)
      eliminated <- c(eliminated, standing$Team[4L])

    # 3rd place is eliminated only when we know who qualified for the R32
    if (nrow(standing) >= 3L && !is.null(knockout_slots) && nrow(knockout_slots) > 0L) {
      third     <- standing$Team[3L]
      r32_teams <- c(knockout_slots$team1, knockout_slots$team2)
      if (!(third %in% r32_teams))
        eliminated <- c(eliminated, third)
    }
  }

  # --- Knockout-stage eliminations ---
  if (!is.null(ko_matches_df) && nrow(ko_matches_df) > 0L) {
    for (i in seq_len(nrow(ko_matches_df))) {
      g1 <- ko_matches_df$goals1[i]
      g2 <- ko_matches_df$goals2[i]
      if (is.na(g1) || is.na(g2)) next

      p1 <- if ("pens1" %in% names(ko_matches_df)) ko_matches_df$pens1[i] else NA_real_
      p2 <- if ("pens2" %in% names(ko_matches_df)) ko_matches_df$pens2[i] else NA_real_

      loser <- if (g1 > g2) ko_matches_df$team2[i]
               else if (g2 > g1) ko_matches_df$team1[i]
               else if (!is.na(p1) && !is.na(p2) && p1 != p2)
                 if (p1 > p2) ko_matches_df$team2[i] else ko_matches_df$team1[i]
               else next

      eliminated <- c(eliminated, loser)
    }
  }

  unique(eliminated)
}

#' Create a results summary
create_results_summary <- function(players_df, matches_df) {
  summary <- players_df %>%
    select(name, country, points) %>%
    arrange(desc(points)) %>%
    mutate(rank = row_number())
  
  return(summary)
}
