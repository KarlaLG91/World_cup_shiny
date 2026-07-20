library(shiny)
library(shinydashboard)
library(dplyr)
library(readr)
library(DT)
library(png)
library(grid)
library(gridExtra)

# Load helper functions
source("R/helpers.R")
source("R/country_allocation.R")
source("R/photo_management.R")
source("R/scoring.R")
source("R/pdf_export.R")
source("R/persistence.R")


# UI Definition
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "WC 2026 Sweepstake"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Setup", tabName = "setup", icon = icon("cog")),
      menuItem("Sweepstake Board", tabName = "board", icon = icon("th")),
      menuItem("Results Tracker", tabName = "results", icon = icon("chart-line")),
      menuItem("Group Stages", tabName = "bracket", icon = icon("list-ol")),
      menuItem("Knockout Stage", tabName = "knockout", icon = icon("sitemap"))
    )
  ),

  dashboardBody(
    tags$head(tags$style(HTML("
      .step-badge {
        display: inline-block; background: #3c8dbc; color: #fff;
        border-radius: 50%; width: 22px; height: 22px; line-height: 22px;
        text-align: center; font-weight: bold; margin-right: 6px; font-size: 12px;
      }
      .vs-label { text-align: center; padding-top: 28px; font-weight: bold; color: #aaa; font-size: 18px; }

      /* ── Knockout bracket ── */
      .bracket { display: flex; gap: 24px; align-items: flex-start;
                 overflow-x: auto; padding: 16px 8px 24px 8px; }
      .ko-round { display: flex; flex-direction: column; min-width: 170px; flex-shrink: 0; }
      .ko-round-label { font-weight: bold; font-size: 12px; text-align: center;
                        color: #fff; border-radius: 4px; padding: 4px 8px; margin-bottom: 10px; }
      .ko-matches-col { display: flex; flex-direction: column;
                        justify-content: space-around; flex: 1; gap: 10px; }
      .ko-match { border: 2px solid #bdc3c7; border-radius: 6px;
                  background: #fff; overflow: hidden; }
      .ko-team { padding: 5px 9px; font-size: 12px; border-bottom: 1px solid #ecf0f1;
                 display: flex; align-items: center; justify-content: space-between; min-height: 28px; }
      .ko-team:last-child { border-bottom: none; }
      .ko-team.winner { font-weight: bold; background: #eafaf1; }
      .ko-team.tbd    { color: #aaa; font-style: italic; }
      .ko-player-badge { border-radius: 3px; padding: 1px 5px; font-size: 10px;
                         margin-right: 5px; color: #fff; white-space: nowrap; }
      .ko-score { font-size: 14px; font-weight: bold; color: #2c3e50; margin-left: 6px; }
      .champion-box { border: 3px solid #f39c12; border-radius: 8px; padding: 10px;
                      text-align: center; background: #fffde7;
                      font-size: 15px; font-weight: bold; min-width: 130px; }

      /* ── Eliminated country / player ── */
      .country-eliminated img  { filter: grayscale(100%); opacity: 0.45; }
      .country-eliminated small { text-decoration: line-through; color: #e74c3c !important;
                                  opacity: 0.8; }
      .player-card-eliminated  { background: #f0f0f0 !important; opacity: 0.75; }
      .eliminated-stamp {
        position: absolute; top: 50%; left: 50%;
        transform: translate(-50%, -50%) rotate(-20deg);
        border: 4px solid #e74c3c; color: #e74c3c;
        padding: 6px 14px; font-size: 22px; font-weight: bold;
        letter-spacing: 2px; border-radius: 4px;
        opacity: 0.85; pointer-events: none; white-space: nowrap; z-index: 10;
      }
    "))),

    tabItems(

      # ── Tab 1: Setup ──────────────────────────────────────────────────────
      tabItem(
        tabName = "setup",
        h2("Sweepstake Setup"),

        fluidRow(
          # Step 1 — Players
          box(
            title = HTML('<span class="step-badge">1</span>Players'),
            width = 6, status = "primary", solidHeader = TRUE,
            textAreaInput(
              "player_names", "Enter names (one per line):",
              rows = 8, placeholder = "Alice\nBob\nCharlie\n..."
            ),
            actionButton("submit_names", "Save Players", class = "btn-primary"),
            tags$span(style = "display:inline-block; width:6px;"),
            downloadButton("export_players", "Export CSV", class = "btn-default btn-sm"),
            tags$span(style = "display:inline-block; width:4px;"),
            actionButton("clear_data", "Clear All", class = "btn-danger btn-sm"),
            hr(),
            dataTableOutput("players_table")
          ),

          # Step 2 — Photos
          box(
            title = HTML('<span class="step-badge" style="background:#00c0ef;">2</span>Player Photos'),
            width = 6, status = "info", solidHeader = TRUE,
            p("Optional — upload a photo for each player, then click Save Photos.",
              style = "color:#555; margin-bottom:12px;"),
            uiOutput("photo_upload_ui"),
            br(),
            actionButton("save_photos", "Save Photos", class = "btn-info")
          )
        ),

        # Step 3 — Country Allocation
        fluidRow(
          box(
            title = HTML('<span class="step-badge" style="background:#00a65a;">3</span>Country Allocation'),
            width = 12, status = "success", solidHeader = TRUE,
            uiOutput("allocation_status"),
            actionButton("allocate_countries", "Allocate Countries", class = "btn-success btn-lg"),
            hr(),
            div(style = "max-height: 320px; overflow-y: auto;",
                dataTableOutput("allocation_table"))
          )
        )
      ),

      # ── Tab 2: Sweepstake Board ────────────────────────────────────────────
      tabItem(
        tabName = "board",
        h2("Sweepstake Board"),
        fluidRow(
          valueBoxOutput("vb_players",   width = 4),
          valueBoxOutput("vb_countries", width = 4),
          valueBoxOutput("vb_matches",   width = 4)
        ),
        uiOutput("sweepstake_board_ui")
      ),

      # ── Tab 3: Group Stages ─────────────────────────────────────────────
      tabItem(
        tabName = "bracket",
        h2("Group Stages"),
        p("Group tables update automatically as you record results. Teams are colour-coded by player.",
          style = "color:#666; margin-bottom:16px;"),
        uiOutput("bracket_legend"),
        br(),
        uiOutput("bracket_ui")
      ),

      # ── Tab 4: Knockout Stage ─────────────────────────────────────────────
      tabItem(
        tabName = "knockout",
        h2("Knockout Stage"),
        p("The Round of 32 is assigned automatically once all group-stage matches have been recorded. Until then, unresolved slots stay as placeholders.",
          style = "color:#666; margin-bottom:16px;"),
        uiOutput("knockout_legend"),
        br(),
        fluidRow(
          box(
            title = "Record Knockout Result",
            width = 12, status = "primary", solidHeader = TRUE,
            fluidRow(
              column(4,
                selectInput("ko_match_id", "Match:", choices = c(
                  setNames(
                    paste0("R32-", 1:16),
                    c(
                      "R32: South Africa vs Canada",
                      "R32: Netherlands vs Morocco",
                      "R32: Germany vs Paraguay",
                      "R32: France vs Sweden",
                      "R32: Belgium vs Senegal",
                      "R32: USA vs Bosnia and Herzegovina",
                      "R32: Spain vs Austria",
                      "R32: Portugal vs Croatia",
                      "R32: Brazil vs Japan",
                      "R32: Ivory Coast vs Norway",
                      "R32: Mexico vs Ecuador",
                      "R32: England vs DR Congo",
                      "R32: Switzerland vs Algeria",
                      "R32: Colombia vs Ghana",
                      "R32: Australia vs Egypt",
                      "R32: Argentina vs Cape Verde"
                    )
                  ),
                  setNames(paste0("R16-",  1:8),  paste0("R16 Match ",   1:8)),
                  setNames(paste0("QF-",   1:4),  paste0("Quarter Final ", 1:4)),
                  setNames(paste0("SF-",   1:2),  paste0("Semi Final ",  1:2)),
                  c("Final" = "F-1", "3rd Place Play-off" = "3P-1")
                ))
              )
            ),
            fluidRow(
              column(3, selectInput("ko_team1_sel", "Team 1:", choices = "TBD")),
              column(2, numericInput("ko_goals1", "Goals:", value = 0, min = 0)),
              column(2, div(class = "vs-label", "vs")),
              column(2, numericInput("ko_goals2", "Goals:", value = 0, min = 0)),
              column(3, selectInput("ko_team2_sel", "Team 2:", choices = "TBD"))
            ),
            fluidRow(
              column(12,
                checkboxInput("ko_penalties", "Went to penalties?", value = FALSE)
              )
            ),
            conditionalPanel(
              condition = "input.ko_penalties == true",
              fluidRow(
                column(3, p("Penalty score:", style = "padding-top: 8px; font-weight: bold;")),
                column(2, numericInput("ko_pens1", "Team 1 pens:", value = 0, min = 0)),
                column(2, div(class = "vs-label", "vs")),
                column(2, numericInput("ko_pens2", "Team 2 pens:", value = 0, min = 0)),
                column(3)
              )
            ),
            br(),
            actionButton("save_ko_result", "Save Result", class = "btn-primary btn-lg")
          )
        ),
        br(),
        uiOutput("knockout_ui")
      ),

      # ── Tab 5: Results Tracker ─────────────────────────────────────────────
      tabItem(
        tabName = "results",
        h2("Results Tracker"),
        fluidRow(
          valueBoxOutput("vb_players_r",   width = 4),
          valueBoxOutput("vb_countries_r", width = 4),
          valueBoxOutput("vb_matches_r",   width = 4)
        ),
        fluidRow(
          box(
            title = "Record Match Result",
            width = 12, status = "primary", solidHeader = TRUE,
            fluidRow(
              column(3, selectInput("match_country1", "Country 1:", choices = list())),
              column(2, numericInput("match_goals1",  "Goals:",     value = 0, min = 0)),
              column(2, div(class = "vs-label", "vs")),
              column(2, numericInput("match_goals2",  "Goals:",     value = 0, min = 0)),
              column(3, selectInput("match_country2", "Country 2:", choices = list()))
            ),
            br(),
            actionButton("save_match", "Record Result", class = "btn-primary btn-lg")
          )
        ),
        fluidRow(
          box(
            title = "Live Standings",
            width = 8, status = "success", solidHeader = TRUE,
            dataTableOutput("standings_table")
          ),
          box(
            title = "Export",
            width = 4, status = "warning", solidHeader = TRUE,
            p("Download the current standings."),
            downloadButton("export_standings", "Standings CSV"),
            br(), br(),
            downloadButton("export_pdf", "Results PDF")
          )
        )
      )

    )
  )
)

# Server Logic
server <- function(input, output, session) {

  # Load persisted data from CSV files
  loaded_data <- load_app_data()
  
  # Reactive values to store data
  rv <- reactiveValues(
    players = loaded_data$players,
    allocations = loaded_data$allocations,
    matches = loaded_data$matches,
    ko_matches = loaded_data$ko_matches,
    photos = list()
  )

  # Get list of World Cup 2026 countries
  world_cup_countries <- get_world_cup_countries()

  output$num_countries <- renderText({
    n <- length(world_cup_countries)
    if (nrow(rv$players) == 0) return(as.character(n))
    per <- floor(n / nrow(rv$players))
    rem <- n %% nrow(rv$players)
    if (rem == 0) paste0(n, " (", per, " per player)")
    else          paste0(n, " (", per, " or ", per + 1, " per player)")
  })

  output$num_players <- renderText({
    nrow(rv$players)
  })

  # Setup tab — Step 2 allocation status message
  output$allocation_status <- renderUI({
    n_p <- nrow(rv$players)
    n_a <- nrow(rv$allocations)
    if (n_p == 0) {
      return(p("Add players in Step 1 first.", style = "color:#888; margin-bottom:10px;"))
    }
    per     <- floor(48 / n_p)
    rem     <- 48 %% n_p
    per_msg <- if (rem == 0) paste0(per, " per player")
               else          paste0(per, " or ", per + 1, " per player")
    if (n_a == 0) {
      p(paste0(n_p, " player", if (n_p != 1) "s" else "", " ready — 48 countries (",
               per_msg, "). Click below to allocate."),
        style = "color:#555; margin-bottom:10px;")
    } else {
      div(
        p(paste0("\u2713 48 countries allocated to ", n_p, " player",
                 if (n_p != 1) "s" else "", " (", per_msg, ")."),
          style = "color:#00a65a; font-weight:bold; margin-bottom:4px;"),
        p("Click Allocate again to re-randomise.",
          style = "color:#888; font-size:12px; margin-bottom:10px;")
      )
    }
  })

  # Status value boxes — Board tab
  output$vb_players <- renderValueBox({
    valueBox(nrow(rv$players), "Players", icon = icon("users"), color = "blue")
  })
  output$vb_countries <- renderValueBox({
    n <- nrow(rv$allocations)
    valueBox(if (n > 0) n else "\u2014", "Countries Allocated",
             icon = icon("globe"), color = if (n > 0) "green" else "red")
  })
  output$vb_matches <- renderValueBox({
    valueBox(nrow(rv$matches), "Matches Recorded", icon = icon("trophy"), color = "yellow")
  })

  # Status value boxes — Results tab (same values, separate output IDs)
  output$vb_players_r <- renderValueBox({
    valueBox(nrow(rv$players), "Players", icon = icon("users"), color = "blue")
  })
  output$vb_countries_r <- renderValueBox({
    n <- nrow(rv$allocations)
    valueBox(if (n > 0) n else "\u2014", "Countries Allocated",
             icon = icon("globe"), color = if (n > 0) "green" else "red")
  })
  output$vb_matches_r <- renderValueBox({
    valueBox(nrow(rv$matches), "Matches Recorded", icon = icon("trophy"), color = "yellow")
  })

  # TAB 1: Setup - Submit player names
  observeEvent(input$submit_names, {
    names_text <- input$player_names
    names_list <- trimws(strsplit(names_text, "\n")[[1]])
    names_list <- names_list[names_list != ""]
    
    if (length(names_list) == 0) {
      showNotification("Please enter at least one player name", type = "error")
      return()
    }
    
    rv$players <- data.frame(
      id     = seq_along(names_list),
      name   = names_list,
      points = 0,
      stringsAsFactors = FALSE
    )
    # Reset allocations whenever the player list changes
    rv$allocations <- data.frame(
      player_id   = integer(),
      player_name = character(),
      country     = character(),
      stringsAsFactors = FALSE
    )
    
    # Save data to files
    save_players(rv$players)
    save_allocations(rv$allocations)

    showNotification(paste("Added", length(names_list), "players"), type = "message")
  })
  
  output$players_table <- renderDataTable({
    rv$players[, c("id", "name", "points")]
  }, options = list(pageLength = 5))
  
  # TAB 2: Country Allocation
  observeEvent(input$allocate_countries, {
    if (nrow(rv$players) == 0) {
      showNotification("Please add players first", type = "error")
      return()
    }

    rv$allocations <- allocate_countries_randomly(rv$players$name)
    
    # Save allocations to file
    save_allocations(rv$allocations)

    # Populate country dropdowns in Results Tracker
    all_countries <- sort(rv$allocations$country)
    updateSelectInput(session, "match_country1", choices = all_countries)
    updateSelectInput(session, "match_country2", choices = all_countries)

    per <- floor(48 / nrow(rv$players))
    rem <- 48 %% nrow(rv$players)
    msg <- if (rem == 0)
      paste0("All 48 countries allocated — ", per, " per player")
    else
      paste0("All 48 countries allocated — ", per, " or ", per + 1, " per player")
    showNotification(msg, type = "message")
  })
  
  output$allocation_table <- renderDataTable({
    if (nrow(rv$allocations) > 0) {
      df <- rv$allocations[order(rv$allocations$player_id), c("player_name", "country")]
      names(df) <- c("Player", "Country")
      df
    } else {
      data.frame()
    }
  }, options = list(pageLength = 16))

  # Keep country dropdowns in sync with allocations (handles relaunch with saved data)
  observe({
    if (nrow(rv$allocations) > 0) {
      all_countries <- sort(rv$allocations$country)
      updateSelectInput(session, "match_country1", choices = all_countries)
      updateSelectInput(session, "match_country2", choices = all_countries)
    }
  })
  
  # TAB 3: Photo Upload UI
  output$photo_upload_ui <- renderUI({
    if (nrow(rv$players) == 0) {
      p("Please add players first in the Setup tab")
      return()
    }
    
    upload_inputs <- lapply(1:nrow(rv$players), function(i) {
      fluidRow(
        column(
          3,
          strong(rv$players$name[i])
        ),
        column(
          5,
          fileInput(
            paste0("photo_", i),
            label = NULL,
            accept = c("image/jpeg", "image/png")
          )
        ),
        column(
          4,
          uiOutput(paste0("photo_status_", i))
        )
      )
    })
    
    do.call(tagList, upload_inputs)
  })

  # TAB 3: Save Photos
  observeEvent(input$save_photos, {
    if (nrow(rv$players) == 0) {
      showNotification("Please add players first", type = "error")
      return()
    }

    saved <- 0
    for (i in seq_len(nrow(rv$players))) {
      file_info <- input[[paste0("photo_", i)]]
      if (!is.null(file_info)) {
        dest <- save_player_photo(file_info$datapath, i)
        rv$photos[[as.character(i)]] <- dest
        saved <- saved + 1
      }
    }

    if (saved > 0)
      showNotification(paste(saved, "photo(s) saved"), type = "message")
    else
      showNotification("No photos selected", type = "warning")
  })
  output$assignment_preview <- renderUI({
    if (nrow(rv$players) == 0 || nrow(rv$allocations) == 0) {
      p("Complete setup and country allocation first")
      return()
    }

    # Depend on rv$photos so the output refreshes after photos are saved
    force(rv$photos)

    preview_cards <- lapply(seq_len(nrow(rv$players)), function(i) {
      player_id   <- rv$players$id[i]
      player_name <- rv$players$name[i]
      photo_path  <- get_photo_path(i)

      player_countries <- rv$allocations$country[rv$allocations$player_id == player_id]

      country_items <- lapply(player_countries, function(country) {
        flag_file <- paste0("www/flags/", tolower(gsub(" ", "_", country)), ".png")
        div(style = "display: flex; align-items: center; gap: 5px; margin: 2px 0;",
          if (file.exists(flag_file))
            tags$img(src = paste0("flags/", tolower(gsub(" ", "_", country)), ".png"),
                     style = "width: 36px; height: 22px;"),
          tags$small(country)
        )
      })

      column(
        3,
        div(
          style = "border: 2px solid #ddd; padding: 10px; margin: 5px; border-radius: 5px; text-align: center;",
          if (!is.null(photo_path))
            tags$img(src = sub("^www/", "", photo_path),
                     style = "width: 80px; height: 80px; border-radius: 50%; margin-bottom: 6px;"),
          h4(player_name),
          tags$small(paste(length(player_countries), "countries")),
          div(style = "max-height: 220px; overflow-y: auto; text-align: left; margin-top: 6px;",
              do.call(tagList, country_items))
        )
      )
    })

    do.call(fluidRow, preview_cards)
  })

  # TAB 3: Tournament Bracket
  # 12 distinguishable player colours (cycles if >12 players)
  PLAYER_COLOURS <- c(
    "#3498db", "#e74c3c", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c",
    "#e67e22", "#e91e63", "#00bcd4", "#8bc34a", "#ff5722", "#607d8b"
  )

  output$bracket_legend <- renderUI({
    if (nrow(rv$players) == 0 || nrow(rv$allocations) == 0) return(NULL)
    items <- lapply(seq_len(nrow(rv$players)), function(i) {
      col <- PLAYER_COLOURS[((i - 1) %% length(PLAYER_COLOURS)) + 1]
      tags$span(
        style = paste0("display:inline-block; background:", col,
                       "; color:#fff; border-radius:4px; padding:3px 10px;",
                       " margin:3px; font-size:13px; font-weight:bold;"),
        rv$players$name[i]
      )
    })
    div(
      tags$strong("Players: "), br(),
      do.call(tagList, items)
    )
  })

  output$bracket_ui <- renderUI({
    if (nrow(rv$allocations) == 0) {
      return(p("Complete Setup (Step 3 — Allocate Countries) first.",
               style = "color:#888;"))
    }

    groups     <- get_world_cup_groups()
    group_names <- names(groups)

    # Build player → colour lookup keyed by country
    country_colour <- setNames(
      PLAYER_COLOURS[((rv$allocations$player_id - 1) %% length(PLAYER_COLOURS)) + 1],
      rv$allocations$country
    )
    country_player <- setNames(rv$allocations$player_name, rv$allocations$country)

    # Render groups in rows of 3
    group_chunks <- split(group_names, ceiling(seq_along(group_names) / 3))

    rows <- lapply(group_chunks, function(chunk) {
      boxes <- lapply(chunk, function(grp) {
        teams    <- groups[[grp]]
        standing <- calculate_group_standings(teams, rv$matches)

        rows_html <- lapply(seq_len(nrow(standing)), function(r) {
          team  <- standing$Team[r]
          col   <- if (!is.null(country_colour[[team]])) country_colour[[team]] else "#95a5a6"
          plyr  <- if (!is.null(country_player[[team]])) country_player[[team]] else ""
          badge <- if (r <= 2)
            tags$span(style = "color:#f39c12; font-size:10px; margin-left:3px;", "\u2605")
          else NULL
          tags$tr(
            tags$td(
              tags$span(
                style = paste0("display:inline-block; background:", col,
                               "; color:#fff; border-radius:3px;",
                               " padding:1px 6px; font-size:11px; margin-right:4px;"),
                plyr
              ),
              team, badge
            ),
            tags$td(standing$P[r]),
            tags$td(standing$W[r]),
            tags$td(standing$D[r]),
            tags$td(standing$L[r]),
            tags$td(standing$GF[r]),
            tags$td(standing$GA[r]),
            tags$td(style = "font-weight:bold;", standing$Pts[r])
          )
        })

        header <- tags$tr(style = "background:#2c3e50; color:#fff;",
          tags$th(paste("Group", grp), style = "min-width:160px;"),
          tags$th("P"), tags$th("W"), tags$th("D"), tags$th("L"),
          tags$th("GF"), tags$th("GA"), tags$th("Pts")
        )

        column(4,
          tags$table(
            class = "table table-condensed table-bordered",
            style = "font-size:12px; margin-bottom:16px;",
            tags$thead(header),
            tags$tbody(do.call(tagList, rows_html))
          )
        )
      })
      do.call(fluidRow, boxes)
    })

    do.call(tagList, rows)
  })

  # TAB 4: Sweepstake Board
  output$sweepstake_board_ui <- renderUI({
    if (nrow(rv$players) == 0) {
      p("Please complete setup first")
      return()
    }

    # Depend on rv$photos so the board refreshes after photos are saved
    force(rv$photos)

    # Compute per-player GF, GA, GD from group-stage AND knockout matches
    player_gf <- setNames(rep(0L, nrow(rv$players)), rv$players$id)
    player_ga <- setNames(rep(0L, nrow(rv$players)), rv$players$id)
    if (nrow(rv$matches) > 0 && nrow(rv$allocations) > 0) {
      for (mi in seq_len(nrow(rv$matches))) {
        c1 <- rv$matches$country1[mi]; c2 <- rv$matches$country2[mi]
        g1 <- rv$matches$goals1[mi];   g2 <- rv$matches$goals2[mi]
        pid1 <- rv$allocations$player_id[rv$allocations$country == c1]
        pid2 <- rv$allocations$player_id[rv$allocations$country == c2]
        if (length(pid1) > 0) { player_gf[as.character(pid1[1])] <- player_gf[as.character(pid1[1])] + g1; player_ga[as.character(pid1[1])] <- player_ga[as.character(pid1[1])] + g2 }
        if (length(pid2) > 0) { player_gf[as.character(pid2[1])] <- player_gf[as.character(pid2[1])] + g2; player_ga[as.character(pid2[1])] <- player_ga[as.character(pid2[1])] + g1 }
      }
    }
    # Also include knockout match goals (normal-time goals only, not penalty shootout)
    if (nrow(rv$ko_matches) > 0 && nrow(rv$allocations) > 0) {
      for (mi in seq_len(nrow(rv$ko_matches))) {
        c1 <- rv$ko_matches$team1[mi]; c2 <- rv$ko_matches$team2[mi]
        g1 <- rv$ko_matches$goals1[mi]; g2 <- rv$ko_matches$goals2[mi]
        if (is.na(g1) || is.na(g2)) next
        pid1 <- rv$allocations$player_id[rv$allocations$country == c1]
        pid2 <- rv$allocations$player_id[rv$allocations$country == c2]
        if (length(pid1) > 0) { player_gf[as.character(pid1[1])] <- player_gf[as.character(pid1[1])] + g1; player_ga[as.character(pid1[1])] <- player_ga[as.character(pid1[1])] + g2 }
        if (length(pid2) > 0) { player_gf[as.character(pid2[1])] <- player_gf[as.character(pid2[1])] + g2; player_ga[as.character(pid2[1])] <- player_ga[as.character(pid2[1])] + g1 }
      }
    }
    player_gd <- player_gf - player_ga

    # Build sort key: primary = points desc, secondary = GD desc, tertiary = GF desc
    pts <- rv$players$points
    ids <- as.character(rv$players$id)
    gd  <- player_gd[ids]
    gf  <- player_gf[ids]
    sorted_indices <- order(pts, gd, gf, decreasing = TRUE)

    # Assign shared ranks: players with the same points share the same rank label
    sorted_pts  <- pts[sorted_indices]
    dense_ranks <- match(sorted_pts, unique(sorted_pts))   # 1 = highest points group
    rank_labels <- c("\U0001F947 1st", "\U0001F948 2nd", "\U0001F949 3rd")
    make_rank_label <- function(r) if (r <= 3) rank_labels[r] else paste0(r, "th")

    # Compute eliminated countries for visual indicators
    eliminated_countries <- get_eliminated_countries(
      get_world_cup_groups(), rv$matches, rv$ko_matches, R32_SLOTS
    )

    # Determine cup winner (winning country + owning player)
    cup_champion_country   <- ko_winner("F-1", rv$ko_matches)
    cup_champion_player_id <- if (!is.null(cup_champion_country) && nrow(rv$allocations) > 0) {
      rows <- rv$allocations[rv$allocations$country == cup_champion_country, ]
      if (nrow(rows) > 0) rows$player_id[1] else NULL
    } else NULL

    board_cards <- lapply(seq_along(sorted_indices), function(pos) {
      i          <- sorted_indices[pos]
      rank       <- dense_ranks[pos]
      player     <- rv$players[i, ]
      photo_path <- get_photo_path(i)

      player_countries <- if (nrow(rv$allocations) > 0)
        rv$allocations$country[rv$allocations$player_id == player$id]
      else character(0)

      country_items <- lapply(player_countries, function(country) {
        is_out    <- country %in% eliminated_countries
        flag_file <- paste0("www/flags/", tolower(gsub(" ", "_", country)), ".png")
        div(
          class = if (is_out) "country-eliminated" else NULL,
          style = "display: flex; align-items: center; gap: 5px; margin: 2px 0;",
          if (file.exists(flag_file))
            tags$img(src = paste0("flags/", tolower(gsub(" ", "_", country)), ".png"),
                     style = "width: 32px; height: 20px;"),
          tags$small(country)
        )
      })

      all_out    <- length(player_countries) > 0 && all(player_countries %in% eliminated_countries)
      is_cup_winner <- !is.null(cup_champion_player_id) && identical(player$id, cup_champion_player_id)
      rank_label <- make_rank_label(rank)
      border_col <- switch(as.character(rank),
        "1" = "#f39c12", "2" = "#95a5a6", "3" = "#cd7f32", "#2c3e50")
      if (is_cup_winner) border_col <- "#f39c12"
      pid_str    <- as.character(player$id)
      p_gf <- player_gf[pid_str]; p_ga <- player_ga[pid_str]; p_gd <- player_gd[pid_str]

      column(
        3,
        div(
          class = if (all_out) "player-card-eliminated" else NULL,
          style = paste0("border: 3px solid ", border_col, "; padding: 15px; margin: 10px; border-radius: 8px; text-align: center; background: #ecf0f1; position: relative;"),
          if (all_out) div(class = "eliminated-stamp", "ELIMINATED"),
          if (is_cup_winner)
            div(style = "background: #f39c12; color: #fff; border-radius: 6px; padding: 4px 10px; font-size: 15px; font-weight: bold; margin-bottom: 8px; letter-spacing: 1px;",
                "\U0001F3C6 Cup Winner!"),
          div(style = "font-size: 18px; font-weight: bold; margin-bottom: 6px;", rank_label),
          if (!is.null(photo_path))
            tags$img(src = sub("^www/", "", photo_path),
                     style = "width: 100px; height: 100px; border-radius: 50%; border: 2px solid #34495e; margin-bottom: 8px;"),
          h3(player$name),
          p(strong("Points: "), player$points, style = "font-size: 16px; color: #27ae60;"),
          p(
            strong("GF: "), p_gf, " | ",
            strong("GA: "), p_ga, " | ",
            strong("GD: "), if (p_gd >= 0) paste0("+", p_gd) else p_gd,
            style = "font-size: 12px; color: #555; margin-top: -6px;"
          ),
          if (length(player_countries) > 0)
            tagList(
              tags$small(paste(length(player_countries), "countries")),
              div(style = "max-height: 200px; overflow-y: auto; text-align: left; margin-top: 6px; font-size: 12px;",
                  do.call(tagList, country_items))
            )
          else
            p("No countries allocated", style = "color: #999;")
        )
      )
    })

    do.call(fluidRow, board_cards)
  })
  
  # TAB 5: Results Tracking
  observeEvent(input$save_match, {
    if (nrow(rv$players) == 0) {
      showNotification("Please complete player setup first", type = "error")
      return()
    }
    
    new_match <- data.frame(
      country1 = input$match_country1,
      goals1 = input$match_goals1,
      country2 = input$match_country2,
      goals2 = input$match_goals2,
      stringsAsFactors = FALSE
    )
    
    rv$matches <- rbind(rv$matches, new_match)
    rv$players <- update_player_points(rv$players, rv$allocations, rv$matches)
    rv$players <- update_ko_points(rv$players, rv$allocations, rv$ko_matches)

    # Save data to files
    save_matches(rv$matches)
    save_players(rv$players)
    
    showNotification("Match result recorded", type = "message")
  })
  
  output$standings_table <- renderDataTable({
    if (nrow(rv$players) > 0) {
      df <- rv$players[order(rv$players$points, decreasing = TRUE), c("name", "points")]
      df$rank <- seq_len(nrow(df))
      df[, c("rank", "name", "points")]
    } else {
      data.frame()
    }
  })
  
  # Export player list
  output$export_players <- downloadHandler(
    filename = function() {
      paste("world_cup_players_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      if (nrow(rv$allocations) > 0) {
        export_df <- merge(
          rv$allocations[, c("player_id", "player_name", "country")],
          rv$players[, c("id", "points")],
          by.x = "player_id", by.y = "id"
        )
        write.csv(
          export_df[order(export_df$player_id), c("player_name", "country", "points")],
          file, row.names = FALSE
        )
      } else {
        write.csv(rv$players[, c("id", "name", "points")], file, row.names = FALSE)
      }
    }
  )

  # Export live standings (Results tab)
  output$export_standings <- downloadHandler(
    filename = function() paste0("standings_", Sys.Date(), ".csv"),
    content = function(file) {
      df <- rv$players[order(rv$players$points, decreasing = TRUE), c("name", "points")]
      df$rank <- seq_len(nrow(df))
      write.csv(df[, c("rank", "name", "points")], file, row.names = FALSE)
    }
  )

  # ── KNOCKOUT STAGE ──────────────────────────────────────────────────────────

  # Hardcoded Round of 32 matchups
  R32_SLOTS <- data.frame(
    match_id = paste0("R32-", 1:16),
    team1 = c(
      "South Africa", "Netherlands",  "Germany",       "France",
      "Belgium",      "United States", "Spain",         "Portugal",
      "Brazil",       "Ivory Coast",   "Mexico",        "England",
      "Switzerland",  "Colombia",      "Australia",     "Argentina"
    ),
    team2 = c(
      "Canada",                  "Morocco",  "Paraguay", "Sweden",
      "Senegal",                 "Bosnia and Herzegovina", "Austria", "Croatia",
      "Japan",                   "Norway",   "Ecuador",  "DR Congo",
      "Algeria",                 "Ghana",    "Egypt",    "Cape Verde"
    ),
    stringsAsFactors = FALSE
  )

  # Helper: get winner of a ko match

  ko_winner <- function(match_id, ko_df) {
    row <- ko_df[ko_df$match_id == match_id, ]
    if (nrow(row) == 0 || is.na(row$goals1) || is.na(row$goals2)) return(NULL)
    if (row$goals1 > row$goals2) return(row$team1)
    if (row$goals2 > row$goals1) return(row$team2)
    # Scores level — check penalty shootout
    p1 <- if ("pens1" %in% names(row)) row$pens1 else NA
    p2 <- if ("pens2" %in% names(row)) row$pens2 else NA
    if (!is.na(p1) && !is.na(p2) && p1 != p2)
      return(if (p1 > p2) row$team1 else row$team2)
    NULL
  }

  # Build R16 slot → which R32 match winners feed it (official FIFA bracket)
  # Google/public route-to-final order.
  # Adjacent R32 boxes feed the next R16 box.
  R16_FROM_R32 <- list(
    "R16-1" = c("R32-1",  "R32-2"),   # South Africa/Canada vs Netherlands/Morocco
    "R16-2" = c("R32-3",  "R32-4"),   # Germany/Paraguay vs France/Sweden
    "R16-3" = c("R32-5",  "R32-6"),   # Belgium/Senegal vs USA/Bosnia
    "R16-4" = c("R32-7",  "R32-8"),   # Spain/Austria vs Portugal/Croatia
    "R16-5" = c("R32-9",  "R32-10"),  # Brazil/Japan vs Ivory Coast/Norway
    "R16-6" = c("R32-11", "R32-12"),  # Mexico/Ecuador vs England/DR Congo
    "R16-7" = c("R32-13", "R32-14"),  # Switzerland/Algeria vs Colombia/Ghana
    "R16-8" = c("R32-15", "R32-16")   # Australia/Egypt vs Argentina/Cape Verde
  )
  QF_FROM_R16 <- list(
    "QF-1" = c("R16-2", "R16-1"),   # Germany/France route vs South Africa/Netherlands route
    "QF-2" = c("R16-5", "R16-6"),   # Portugal/Spain route vs USA/Belgium route
    "QF-3" = c("R16-3", "R16-4"),   # Brazil/Ivory Coast route vs Mexico/England route
    "QF-4" = c("R16-7", "R16-8")    # Argentina/Australia route vs Switzerland/Colombia route
  )
  SF_FROM_QF <- list(
    "SF-1" = c("QF-3", "QF-1"),
    "SF-2" = c("QF-4", "QF-2")
  )
  FINAL_FROM_SF  <- list("F-1"  = c("SF-1", "SF-2"))

  # Build a match card UI widget
  # R NULL-coalescing helper
  `%||%` <- function(a, b) if (!is.null(a)) a else b

  # Server: knockout legend (same as group legend)
  output$knockout_legend <- renderUI({
    if (nrow(rv$players) == 0 || nrow(rv$allocations) == 0) return(NULL)
    items <- lapply(seq_len(nrow(rv$players)), function(i) {
      col <- PLAYER_COLOURS[((i - 1) %% length(PLAYER_COLOURS)) + 1]
      tags$span(
        style = paste0("display:inline-block; background:", col,
                       "; color:#fff; border-radius:4px; padding:3px 10px;",
                       " margin:3px; font-size:13px; font-weight:bold;"),
        rv$players$name[i]
      )
    })
    div(tags$strong("Players: "), br(), do.call(tagList, items))
  })

  # Server: knockout bracket UI
  output$knockout_ui <- renderUI({
    ko_df <- rv$ko_matches
    alloc <- rv$allocations

    # Resolve a slot to the actual team name
    slot_team <- function(slot) {
      if (startsWith(slot, "W:")) {
        mid <- sub("^W:", "", slot)
        ko_winner(mid, ko_df) %||% paste0("W:", mid)
      } else if (startsWith(slot, "L:")) {
        mid <- sub("^L:", "", slot)
        row <- ko_df[ko_df$match_id == mid, ]
        if (nrow(row) == 0 || is.na(row$goals1) || is.na(row$goals2)) return(paste0("L:", mid))
        if (row$goals1 < row$goals2) row$team1 else row$team2
      } else slot
    }

    # R32 teams are hardcoded
    r32_t1 <- setNames(R32_SLOTS$team1, R32_SLOTS$match_id)[paste0("R32-", 1:16)]
    r32_t2 <- setNames(R32_SLOTS$team2, R32_SLOTS$match_id)[paste0("R32-", 1:16)]
    r16_t1 <- sapply(paste0("R16-", 1:8),  function(id) slot_team(paste0("W:", R16_FROM_R32[[id]][1])))
    r16_t2 <- sapply(paste0("R16-", 1:8),  function(id) slot_team(paste0("W:", R16_FROM_R32[[id]][2])))
    qf_t1  <- sapply(paste0("QF-",  1:4),  function(id) slot_team(paste0("W:", QF_FROM_R16[[id]][1])))
    qf_t2  <- sapply(paste0("QF-",  1:4),  function(id) slot_team(paste0("W:", QF_FROM_R16[[id]][2])))
    sf_t1  <- sapply(1:2, function(i) slot_team(paste0("W:", SF_FROM_QF[[paste0("SF-", i)]][1])))
    sf_t2  <- sapply(1:2, function(i) slot_team(paste0("W:", SF_FROM_QF[[paste0("SF-", i)]][2])))
    final_t1 <- slot_team("W:SF-1"); final_t2 <- slot_team("W:SF-2")
    third_t1 <- slot_team("L:SF-1"); third_t2 <- slot_team("L:SF-2")
    champion <- ko_winner("F-1", ko_df)

    # Look up player colour / name for a country
    colour_of <- function(team) {
      if (is.null(alloc) || nrow(alloc) == 0) return("#95a5a6")
      row <- alloc[alloc$country == team, ]
      if (nrow(row) == 0) return("#95a5a6")
      PLAYER_COLOURS[((row$player_id[1] - 1L) %% length(PLAYER_COLOURS)) + 1L]
    }
    player_of <- function(team) {
      if (is.null(alloc) || nrow(alloc) == 0) return("")
      row <- alloc[alloc$country == team, ]
      if (nrow(row) == 0) "" else row$player_name[1]
    }

    # Render one team row inside a match card
    team_row <- function(team, goals, is_win) {
      is_tbd <- is.null(team) || grepl("^(W:|L:|1[A-L]|2[A-L]|3[A-Z])", team %||% "")
      col    <- if (!is_tbd) colour_of(team) else "#95a5a6"
      plyr   <- if (!is_tbd) player_of(team) else ""
      cls    <- paste0("ko-team",
                       if (!is_tbd && isTRUE(is_win)) " winner" else "",
                       if (is_tbd) " tbd" else "")
      div(class = cls,
        div(
          if (nchar(plyr) > 0)
            tags$span(class = "ko-player-badge",
                      style = paste0("background:", col, ";"), plyr),
          if (!is_tbd) team else if (!is.null(team) && nchar(team) > 0) team else "TBD"
        ),
        tags$span(class = "ko-score",
                  if (!is.na(goals)) as.character(goals) else "")
      )
    }

    # Render a full match card (two team rows)
    mk <- function(mid, t1, t2) {
      row <- ko_df[ko_df$match_id == mid, ]
      # Detect if teams were stored in reverse order and swap goals accordingly
      swapped <- nrow(row) > 0 &&
                 !is.na(row$team1) && !is.na(row$team2) &&
                 isTRUE(row$team1 == t2) && isTRUE(row$team2 == t1)
      g1  <- if (nrow(row) > 0 && !is.na(if (swapped) row$goals2 else row$goals1))
               (if (swapped) row$goals2 else row$goals1) else NA
      g2  <- if (nrow(row) > 0 && !is.na(if (swapped) row$goals1 else row$goals2))
               (if (swapped) row$goals1 else row$goals2) else NA
      p1  <- if (nrow(row) > 0 && "pens1" %in% names(row) &&
                 !is.na(if (swapped) row$pens2 else row$pens1))
               (if (swapped) row$pens2 else row$pens1) else NA
      p2  <- if (nrow(row) > 0 && "pens2" %in% names(row) &&
                 !is.na(if (swapped) row$pens1 else row$pens2))
               (if (swapped) row$pens1 else row$pens2) else NA
      has_pens <- !is.na(p1) && !is.na(p2)
      w   <- if (!is.na(g1) && !is.na(g2)) {
        if (g1 > g2) t1
        else if (g2 > g1) t2
        else if (has_pens && p1 != p2) (if (p1 > p2) t1 else t2)
        else NULL
      } else NULL
      s1  <- if (!is.na(g1)) paste0(g1, if (has_pens) paste0(" (", p1, "p)") else "") else NA
      s2  <- if (!is.na(g2)) paste0(g2, if (has_pens) paste0(" (", p2, "p)") else "") else NA
      div(class = "ko-match",
        team_row(t1, s1, !is.null(w) && identical(w, t1)),
        team_row(t2, s2, !is.null(w) && identical(w, t2))
      )
    }

    # Render one round column
    ko_round <- function(label, colour, match_list) {
      div(class = "ko-round",
        div(class = "ko-round-label",
            style = paste0("background:", colour, ";"), label),
        div(class = "ko-matches-col", do.call(tagList, match_list))
      )
    }

    tagList(
      div(class = "bracket",
        ko_round("Round of 32", "#8e44ad",
          lapply(1:16, function(i) mk(paste0("R32-", i), r32_t1[i], r32_t2[i]))
        ),
        ko_round("Round of 16", "#2980b9",
          lapply(1:8,  function(i) mk(paste0("R16-", i), r16_t1[i], r16_t2[i]))
        ),
        ko_round("Quarter Finals", "#27ae60",
          lapply(1:4,  function(i) mk(paste0("QF-",  i), qf_t1[i],  qf_t2[i]))
        ),
        ko_round("Semi Finals", "#e67e22",
          list(mk("SF-1", sf_t1[1], sf_t2[1]),
               mk("SF-2", sf_t1[2], sf_t2[2]))
        ),
        div(class = "ko-round",
          div(class = "ko-round-label", style = "background:#c0392b;", "\U1F3C6 Final"),
          div(class = "ko-matches-col",
            mk("F-1", final_t1, final_t2),
            div(style = "margin-top:16px;",
              div(class = "ko-round-label", style = "background:#7f8c8d;", "\U1F949 3rd Place"),
              mk("3P-1", third_t1, third_t2)
            )
          )
        ),
        if (!is.null(champion)) {
          div(class = "ko-round",
            div(class = "ko-round-label", style = "background:#f39c12;", "Champion"),
            div(class = "ko-matches-col",
              div(class = "champion-box",
                div(style = paste0("color:", colour_of(champion), "; font-size:28px;"), "\U1F947"),
                div(style = paste0("background:", colour_of(champion),
                                   "; color:#fff; border-radius:4px;",
                                   " padding:4px 10px; margin:6px auto; display:inline-block;"),
                    player_of(champion)),
                div(style = "margin-top:6px; font-size:16px;", champion)
              )
            )
          )
        }
      )
    )
  })

  # Reactively populate team dropdowns when match selection or results change
  observe({
    req(input$ko_match_id)
    mid   <- input$ko_match_id
    ko_df <- rv$ko_matches

    slot_t <- function(slot) {
      if (startsWith(slot, "W:")) {
        m <- sub("^W:", "", slot)
        ko_winner(m, ko_df) %||% paste0("W:", m)
      } else if (startsWith(slot, "L:")) {
        m <- sub("^L:", "", slot)
        row <- ko_df[ko_df$match_id == m, ]
        if (nrow(row) == 0 || is.na(row$goals1) || is.na(row$goals2)) return(paste0("L:", m))
        if (row$goals1 < row$goals2) row$team1 else row$team2
      } else slot
    }

    r32_row <- R32_SLOTS[R32_SLOTS$match_id == mid, ]

    t1 <- tryCatch({
      if (startsWith(mid, "R32-"))      r32_row$team1[1]
      else if (startsWith(mid, "R16-")) slot_t(paste0("W:", R16_FROM_R32[[mid]][1]))
      else if (startsWith(mid, "QF-"))  slot_t(paste0("W:", QF_FROM_R16[[mid]][1]))
      else if (mid == "SF-1")           slot_t(paste0("W:", SF_FROM_QF[["SF-1"]][1]))
      else if (mid == "SF-2")           slot_t(paste0("W:", SF_FROM_QF[["SF-2"]][1]))
      else if (mid == "F-1")            slot_t("W:SF-1")
      else if (mid == "3P-1")           slot_t("L:SF-1")
      else mid
    }, error = function(e) mid)

    t2 <- tryCatch({
      if (startsWith(mid, "R32-"))      r32_row$team2[1]
      else if (startsWith(mid, "R16-")) slot_t(paste0("W:", R16_FROM_R32[[mid]][2]))
      else if (startsWith(mid, "QF-"))  slot_t(paste0("W:", QF_FROM_R16[[mid]][2]))
      else if (mid == "SF-1")           slot_t(paste0("W:", SF_FROM_QF[["SF-1"]][2]))
      else if (mid == "SF-2")           slot_t(paste0("W:", SF_FROM_QF[["SF-2"]][2]))
      else if (mid == "F-1")            slot_t("W:SF-2")
      else if (mid == "3P-1")           slot_t("L:SF-2")
      else mid
    }, error = function(e) mid)

    updateSelectInput(session, "ko_team1_sel", choices = t1, selected = t1)
    updateSelectInput(session, "ko_team2_sel", choices = t2, selected = t2)
    updateCheckboxInput(session, "ko_penalties", value = FALSE)
  })

  # Save a knockout result
  observeEvent(input$save_ko_result, {
    mid          <- input$ko_match_id
    ko_df        <- rv$ko_matches
    t1           <- input$ko_team1_sel
    t2           <- input$ko_team2_sel
    went_to_pens <- isTRUE(input$ko_penalties)
    p1           <- if (went_to_pens) input$ko_pens1 else NA_real_
    p2           <- if (went_to_pens) input$ko_pens2 else NA_real_

    new_row <- data.frame(stage = sub("-.*", "", mid), match_id = mid,
                          team1 = t1, goals1 = input$ko_goals1,
                          team2 = t2, goals2 = input$ko_goals2,
                          pens1 = p1, pens2 = p2,
                          stringsAsFactors = FALSE)
    # Upsert
    rv$ko_matches <- rbind(ko_df[ko_df$match_id != mid, ], new_row)

    # Recalculate all points: group stage first, then KO on top
    rv$players <- update_player_points(rv$players, rv$allocations, rv$matches)
    rv$players <- update_ko_points(rv$players, rv$allocations, rv$ko_matches)

    # Save data to files
    save_ko_matches(rv$ko_matches)
    save_players(rv$players)

    score_str <- paste0(t1, " ", input$ko_goals1, " - ", input$ko_goals2, " ", t2)
    if (went_to_pens) score_str <- paste0(score_str, " (pens: ", p1, "-", p2, ")")
    showNotification(paste("Knockout result saved:", score_str), type = "message")
  })

  # ── KNOCKOUT STAGE end ───────────────────────────────────────────────────

  # Clear all data
  observeEvent(input$clear_data, {
    rv$players <- data.frame(
      id = integer(), name = character(), points = numeric(),
      stringsAsFactors = FALSE
    )
    rv$allocations <- data.frame(
      player_id = integer(), player_name = character(), country = character(),
      stringsAsFactors = FALSE
    )
    rv$matches <- data.frame(
      country1 = character(), goals1 = numeric(),
      country2 = character(), goals2 = numeric(),
      stringsAsFactors = FALSE
    )
    rv$ko_matches <- data.frame(
      stage = character(), match_id = character(),
      team1 = character(), goals1 = numeric(),
      team2 = character(), goals2 = numeric(),
      pens1 = numeric(), pens2 = numeric(),
      stringsAsFactors = FALSE
    )
    # Save empty data to files
    save_app_data(rv$players, rv$allocations, rv$matches, rv$ko_matches)
    
    updateSelectInput(session, "match_country1", choices = list())
    updateSelectInput(session, "match_country2", choices = list())
    showNotification("All data cleared", type = "message")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
