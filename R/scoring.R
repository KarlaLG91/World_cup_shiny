# Points and scoring functions

#' Update player points based on match results.
#' Scoring: Win = 3 points, Draw = 1 point, Loss = 0 points.
#' Each player may own multiple countries; allocations_df maps country -> player_id.
#' Points are recalculated from scratch on every call.
update_player_points <- function(players_df, allocations_df, matches_df) {

  if (nrow(matches_df) == 0) return(players_df)

  players_df$points <- 0

  for (i in seq_len(nrow(matches_df))) {
    country1 <- matches_df$country1[i]
    country2 <- matches_df$country2[i]
    goals1   <- matches_df$goals1[i]
    goals2   <- matches_df$goals2[i]

    # Award points to the player who owns country1
    idx1 <- which(allocations_df$country == country1)
    if (length(idx1) > 0) {
      pid1 <- allocations_df$player_id[idx1[1]]
      row1 <- which(players_df$id == pid1)
      if (goals1 > goals2)       players_df$points[row1] <- players_df$points[row1] + 3
      else if (goals1 == goals2) players_df$points[row1] <- players_df$points[row1] + 1
    }

    # Award points to the player who owns country2
    idx2 <- which(allocations_df$country == country2)
    if (length(idx2) > 0) {
      pid2 <- allocations_df$player_id[idx2[1]]
      row2 <- which(players_df$id == pid2)
      if (goals2 > goals1)       players_df$points[row2] <- players_df$points[row2] + 3
      else if (goals2 == goals1) players_df$points[row2] <- players_df$points[row2] + 1
    }
  }

  return(players_df)
}

#' Calculate standings from players dataframe
calculate_standings <- function(players_df) {
  standings <- players_df %>%
    select(name, country, points) %>%
    arrange(desc(points)) %>%
    mutate(
      rank = row_number(),
      position = case_when(
        rank == 1 ~ "🥇 1st",
        rank == 2 ~ "🥈 2nd",
        rank == 3 ~ "🥉 3rd",
        TRUE ~ paste0(rank, "th")
      )
    )
  
  return(standings)
}

#' Get match history
get_match_history <- function(matches_df, players_df) {
  if (nrow(matches_df) == 0) {
    return(data.frame())
  }
  
  history <- matches_df %>%
    mutate(
      result = case_when(
        goals1 > goals2 ~ paste0(country1, " won"),
        goals2 > goals1 ~ paste0(country2, " won"),
        TRUE ~ "Draw"
      ),
      score = paste0(goals1, " - ", goals2),
      match_id = row_number()
    ) %>%
    select(match_id, country1, score, country2, result)
  
  return(history)
}

#' Get player match record
get_player_matches <- function(player_country, matches_df) {
  matches_list <- list()
  
  for (i in 1:nrow(matches_df)) {
    match <- matches_df[i, ]
    
    if (match$country1 == player_country) {
      matches_list[[length(matches_list) + 1]] <- data.frame(
        opponent = match$country2,
        goals_for = match$goals1,
        goals_against = match$goals2,
        result = if (match$goals1 > match$goals2) "W" 
                 else if (match$goals1 < match$goals2) "L" 
                 else "D",
        points = if (match$goals1 > match$goals2) 3
                 else if (match$goals1 == match$goals2) 1
                 else 0
      )
    } else if (match$country2 == player_country) {
      matches_list[[length(matches_list) + 1]] <- data.frame(
        opponent = match$country1,
        goals_for = match$goals2,
        goals_against = match$goals1,
        result = if (match$goals2 > match$goals1) "W"
                 else if (match$goals2 < match$goals1) "L"
                 else "D",
        points = if (match$goals2 > match$goals1) 3
                 else if (match$goals2 == match$goals1) 1
                 else 0
      )
    }
  }
  
  if (length(matches_list) == 0) {
    return(data.frame())
  }
  
  return(do.call(rbind, matches_list))
}
