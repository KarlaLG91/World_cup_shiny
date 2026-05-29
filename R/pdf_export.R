# PDF Export and Report Generation Functions

#' Generate PDF report with results
generate_pdf_report <- function(players_df, matches_df, output_file) {
  
  library(gridExtra)
  library(grid)
  
  # Get standings
  standings <- calculate_standings(players_df)
  
  # Create a table grob for standings
  standings_grob <- tableGrob(
    standings[, c("position", "name", "country", "points")],
    cols = c("Position", "Player", "Country", "Points"),
    theme = ttheme_default(base_size = 10)
  )
  
  # Create title
  title_grob <- textGrob(
    "FIFA World Cup 2026 Sweepstake Results",
    gp = gpar(fontsize = 20, fontface = "bold"),
    just = "center"
  )
  
  # Combine and save
  pdf(output_file, width = 8.5, height = 11)
  grid.arrange(title_grob, standings_grob, ncol = 1, heights = c(0.1, 0.9))
  dev.off()
  
  return(output_file)
}

#' Create HTML report
create_html_report <- function(players_df, matches_df) {
  standings <- calculate_standings(players_df)
  
  html_content <- paste0(
    "<!DOCTYPE html>
    <html>
    <head>
      <title>World Cup 2026 Sweepstake</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; border-bottom: 3px solid #2c3e50; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { 
          border: 1px solid #ddd; 
          padding: 12px; 
          text-align: left; 
        }
        th { background-color: #2c3e50; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #ecf0f1; }
        .medal { font-size: 20px; }
      </style>
    </head>
    <body>
      <h1>🏆 FIFA World Cup 2026 Sweepstake</h1>
      <h2>Current Standings</h2>
      <table>
        <tr>
          <th>Position</th>
          <th>Player</th>
          <th>Country</th>
          <th>Points</th>
        </tr>"
  )
  
  for (i in 1:nrow(standings)) {
    row <- standings[i, ]
    medal <- switch(row$rank,
                   "🥇",
                   "🥈",
                   "🥉",
                   "")
    html_content <- paste0(
      html_content,
      "<tr>
        <td>", medal, " ", row$position, "</td>
        <td>", row$name, "</td>
        <td>", row$country, "</td>
        <td><strong>", row$points, "</strong></td>
      </tr>"
    )
  }
  
  html_content <- paste0(html_content, "</table></body></html>")
  
  return(html_content)
}
