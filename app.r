library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(readr)
library(plotly)
library(DT)

# ==========================================
#   SETUP & DATA LOADING
# ==========================================
df <- read_csv("data/processed/processed_global_education.csv", show_col_types = FALSE)

table_feature_choices <- names(df)

region_choices <- c(
  "North America", "South America", "Europe",
  "Asia", "Africa", "Oceania"
)

region_color_map <- c(
  "North America" = "#66c2a5",
  "South America" = "#fc8d62",
  "Europe" = "#8da0cb",
  "Asia" = "#e78ac3",
  "Africa" = "#a6d854",
  "Oceania" = "#ffd92f"
)

map_metric_choices <- list(
  "Access" = c(
    "Out-of-school rate (Primary, avg)" = "OOSR_Avg_Primary",
    "Out-of-school rate (Lower secondary, avg)" = "OOSR_Avg_Lower_Secondary",
    "Out-of-school rate (Upper secondary, avg)" = "OOSR_Avg_Upper_Secondary",
    "Out-of-school rate gender gap (Primary)" = "OOSR_Gap_Primary",
    "Out-of-school rate gender gap (Lower secondary)" = "OOSR_Gap_Lower_Secondary",
    "Out-of-school rate gender gap (Upper secondary)" = "OOSR_Gap_Upper_Secondary",
    "Gross primary enrollment" = "Gross_Primary_Education_Enrollment",
    "Gross tertiary enrollment" = "Gross_Tertiary_Education_Enrollment"
  ),
  "Completion" = c(
    "Completion rate (Primary, avg)" = "Completion_Avg_Primary",
    "Completion rate (Lower secondary, avg)" = "Completion_Avg_Lower_Secondary",
    "Completion rate (Upper secondary, avg)" = "Completion_Avg_Upper_Secondary",
    "Completion rate gender gap (Primary)" = "Completion_Gap_Primary",
    "Completion rate gender gap (Lower secondary)" = "Completion_Gap_Lower_Secondary",
    "Completion rate gender gap (Upper secondary)" = "Completion_Gap_Upper_Secondary"
  ),
  "Learning" = c(
    "Grade 2–3 proficiency (Reading)" = "Grade_2_3_Proficiency_Reading",
    "Grade 2–3 proficiency (Math)" = "Grade_2_3_Proficiency_Math",
    "Primary end proficiency (Reading)" = "Primary_End_Proficiency_Reading",
    "Primary end proficiency (Math)" = "Primary_End_Proficiency_Math",
    "Lower secondary end proficiency (Reading)" = "Lower_Secondary_End_Proficiency_Reading",
    "Lower secondary end proficiency (Math)" = "Lower_Secondary_End_Proficiency_Math"
  ),
  "Context" = c(
    "Youth literacy rate (Male)" = "Youth_15_24_Literacy_Rate_Male",
    "Youth literacy rate (Female)" = "Youth_15_24_Literacy_Rate_Female",
    "Youth literacy gender gap (Male - Female)" = "Literacy_Gap",
    "Birth rate" = "Birth_Rate",
    "Unemployment rate" = "Unemployment_Rate"
  )
)

metric_label <- function(metric_key) {
  for (group in map_metric_choices) {
    if (metric_key %in% group) {
      return(names(group)[match(metric_key, group)])
    }
  }
  metric_key
}

kpi_card <- function(title, value, subtitle = NULL, bg = "#f8f9fa") {
  div(
    style = paste0(
      "background:", bg, "; padding:16px; border-radius:12px; ",
      "box-shadow:0 1px 4px rgba(0,0,0,0.08); margin-bottom:12px;"
    ),
    div(style = "font-size:14px; color:#555; margin-bottom:8px;", title),
    div(style = "font-size:28px; font-weight:700;", value),
    if (!is.null(subtitle)) {
      div(style = "font-size:13px; color:#666; margin-top:6px;", subtitle)
    }
  )
}

# ==========================================
#   UI
# ==========================================
ui <- page_fluid(
  theme = bs_theme(version = 5),
  tags$head(tags$title("World Education Dashboard")),

  navset_tab(
    nav_panel(
      "Main Dashboard",
      h2("World Education Dashboard"),

      layout_sidebar(
        sidebar = sidebar(
          width = 300,
          card(
            card_header("Filters"),
            checkboxGroupInput(
              "input_region",
              "Select Region:",
              choices = region_choices,
              selected = region_choices
            ),
            div(
              actionButton("select_all_regions", "Select All", class = "btn btn-outline-primary btn-sm me-2"),
              actionButton("reset_regions", "Reset", class = "btn btn-outline-secondary btn-sm")
            ),
            p(
              "The selected regions apply to the map and KPI cards in the Overview tab, charts in the Completion & Literacy tab, and the table in the Data Table tab.",
              class = "text-muted small mt-2"
            )
          )
        ),

        navset_tab(
          nav_panel(
            "Overview",
            layout_columns(
              card(
                card_header("Global Education Indicators Map"),
                p(
                  "Select a metric to map across the chosen regions. The region filter also updates the KPI cards.",
                  class = "text-muted small"
                ),
                selectInput(
                  "input_map_metric",
                  "Map metric",
                  choices = map_metric_choices,
                  selected = "OOSR_Avg_Primary"
                ),
                plotlyOutput("world_map", height = "450px")
              ),
              div(
                uiOutput("metric_average_box"),
                uiOutput("metric_vs_world_box"),
                uiOutput("metric_coverage_box")
              ),
              col_widths = c(8, 4)
            )
          ),

          nav_panel(
            "Completion & Literacy",
            layout_column_wrap(
              width = 1/3,
              card(
                card_header("Average Education Level by Region"),
                p("Compare regional patterns in average education level", class = "text-muted small"),
                plotlyOutput("education_level_by_region_bar")
              ),
              card(
                card_header("Completion Rate Gap by Region"),
                p("Compare regional patterns in completion rate gap between genders", class = "text-muted small"),
                plotlyOutput("completion_rate_gap_by_region_bar")
              ),
              card(
                card_header("Male vs Female Literacy Rate by Region"),
                p("Compare regional patterns in gender disparities in literacy rates", class = "text-muted small"),
                plotlyOutput("literacy_scatterplot")
              )
            )
          ),

          nav_panel(
            "Data Table",
            card(
              card_header("Data Table"),
              p("Inspect the filtered country-level data and choose which features to display", class = "text-muted"),
              selectizeInput(
                "input_table_features",
                "Table features:",
                choices = table_feature_choices,
                selected = c("Countries and areas", "Region"),
                multiple = TRUE
              ),
              DTOutput("tbl")
            )
          )
        )
      )
    )
  )
)

# ==========================================
#   SERVER
# ==========================================
server <- function(input, output, session) {

  processed_df <- reactive({
    df
  })

  filtered_df <- reactive({
    d <- processed_df()

    if (!is.null(input$input_region) && length(input$input_region) > 0) {
      d <- d %>% filter(Region %in% input$input_region)
    }

    d
  })

  selected_metric <- reactive({
    req(input$input_map_metric)
    input$input_map_metric
  })

  filtered_metric_series <- reactive({
    metric <- selected_metric()
    filtered_df() %>%
      pull(all_of(metric)) %>%
      .[!is.na(.)]
  })

  global_metric_series <- reactive({
    metric <- selected_metric()
    df %>%
      pull(all_of(metric)) %>%
      .[!is.na(.)]
  })

  region_completion_rate_df <- reactive({
    filtered_df() %>%
      select(
        Region, iso3,
        Completion_Avg_Primary,
        Completion_Avg_Lower_Secondary,
        Completion_Avg_Upper_Secondary
      ) %>%
      pivot_longer(
        cols = c(
          Completion_Avg_Primary,
          Completion_Avg_Lower_Secondary,
          Completion_Avg_Upper_Secondary
        ),
        names_to = "Completion_Rate_Group",
        values_to = "Completion_Rate"
      ) %>%
      mutate(
        Education_Level = gsub("_", " ", sub("Completion_Avg_", "", Completion_Rate_Group))
      ) %>%
      group_by(Region, Education_Level) %>%
      summarise(Completion_Rate = mean(Completion_Rate, na.rm = TRUE), .groups = "drop")
  })

  completion_gap_by_region_df <- reactive({
    filtered_df() %>%
      select(
        Region,
        Completion_Gap_Primary,
        Completion_Gap_Lower_Secondary,
        Completion_Gap_Upper_Secondary
      ) %>%
      pivot_longer(
        cols = c(
          Completion_Gap_Primary,
          Completion_Gap_Lower_Secondary,
          Completion_Gap_Upper_Secondary
        ),
        names_to = "Gap_Group",
        values_to = "Completion_Rate_Gap"
      ) %>%
      mutate(
        Education_Level = gsub("_", " ", sub("Completion_Gap_", "", Gap_Group))
      ) %>%
      group_by(Region, Education_Level) %>%
      summarise(Completion_Rate_Gap = mean(Completion_Rate_Gap, na.rm = TRUE), .groups = "drop")
  })

  observeEvent(input$select_all_regions, {
    updateCheckboxGroupInput(session, "input_region", selected = region_choices)
  })

  observeEvent(input$reset_regions, {
    updateCheckboxGroupInput(session, "input_region", selected = region_choices)
  })

  output$world_map <- renderPlotly({
    d <- filtered_df()
    metric <- selected_metric()

    plot_ly(
      data = d,
      type = "choropleth",
      locations = ~iso3,
      z = as.formula(paste0("~`", metric, "`")),
      text = ~`Countries and areas`,
      colorscale = "Viridis",
      marker = list(line = list(color = "white", width = 0.5)),
      hovertemplate = paste(
        "%{text}<br>",
        metric_label(metric), ": %{z}<extra></extra>"
      )
    ) %>%
      layout(
        geo = list(
          projection = list(type = "natural earth"),
          showcoastlines = TRUE,
          showcountries = TRUE,
          showframe = FALSE
        ),
        margin = list(l = 0, r = 0, t = 30, b = 0)
      )
  })

  output$literacy_scatterplot <- renderPlotly({
    d <- filtered_df()
    req(nrow(d) > 0)

    xy_min <- min(
      c(d$Youth_15_24_Literacy_Rate_Male, d$Youth_15_24_Literacy_Rate_Female),
      na.rm = TRUE
    ) - 5

    xy_max <- max(
      c(d$Youth_15_24_Literacy_Rate_Male, d$Youth_15_24_Literacy_Rate_Female),
      na.rm = TRUE
    ) + 5

    axis_range <- xy_max - xy_min
    tick_size <- if (axis_range < 15) {
      2
    } else if (axis_range < 40) {
      5
    } else {
      10
    }

    plot_ly(
      data = d,
      x = ~Youth_15_24_Literacy_Rate_Male,
      y = ~Youth_15_24_Literacy_Rate_Female,
      type = "scatter",
      mode = "markers",
      color = ~Region,
      colors = region_color_map,
      text = ~`Countries and areas`,
      hovertemplate = paste(
        "%{text}<br>Male Literacy: %{x}<br>Female Literacy: %{y}<extra></extra>"
      )
    ) %>%
      layout(
        xaxis = list(
          title = "Male Literacy Rate (%)",
          range = c(xy_min, xy_max),
          dtick = tick_size
        ),
        yaxis = list(
          title = "Female Literacy Rate (%)",
          range = c(xy_min, xy_max),
          dtick = tick_size
        ),
        shapes = list(
          list(
            type = "line",
            x0 = -10, y0 = -10,
            x1 = 110, y1 = 110,
            line = list(color = "black", dash = "dash")
          )
        )
      )
  })

  output$education_level_by_region_bar <- renderPlotly({
    d <- region_completion_rate_df()

    d$Education_Level <- factor(
      d$Education_Level,
      levels = c("Primary", "Lower Secondary", "Upper Secondary")
    )

    plot_ly(
      data = d,
      x = ~Education_Level,
      y = ~Completion_Rate,
      color = ~Region,
      colors = region_color_map,
      type = "bar"
    ) %>%
      layout(
        barmode = "group",
        yaxis = list(title = "Completion Rate (%)", range = c(0, 100), dtick = 20),
        xaxis = list(title = "Education Level")
      )
  })

  output$completion_rate_gap_by_region_bar <- renderPlotly({
    d <- completion_gap_by_region_df()

    d$Education_Level <- factor(
      d$Education_Level,
      levels = c("Primary", "Lower Secondary", "Upper Secondary")
    )

    plot_ly(
      data = d,
      x = ~Education_Level,
      y = ~Completion_Rate_Gap,
      color = ~Region,
      colors = region_color_map,
      type = "bar"
    ) %>%
      layout(
        barmode = "group",
        yaxis = list(title = "Completion Rate Gap (Male - Female, %)", dtick = 2),
        xaxis = list(title = "Education Level"),
        shapes = list(
          list(
            type = "line",
            x0 = -0.5, x1 = 2.5,
            y0 = 0, y1 = 0,
            line = list(color = "black", dash = "dash")
          )
        )
      )
  })

  output$tbl <- renderDT({
    d <- filtered_df()
    selected_cols <- input$input_table_features

    if (is.null(selected_cols) || length(selected_cols) == 0) {
      selected_cols <- names(d)
    }

    cols <- selected_cols[selected_cols %in% names(d)]

    datatable(
      d[, cols, drop = FALSE],
      options = list(pageLength = 10, scrollX = TRUE)
    )
  })

  output$metric_average_box <- renderUI({
    metric <- selected_metric()
    label <- metric_label(metric)
    values <- filtered_metric_series()

    if (length(values) == 0) {
      return(kpi_card(
        paste("Average:", label),
        "No data",
        bg = "#e9ecef"
      ))
    }

    avg_value <- mean(values, na.rm = TRUE)

    kpi_card(
      paste("Average:", label),
      sprintf("%.1f", avg_value),
      "Across selected regions",
      bg = "#dbeafe"
    )
  })

  output$metric_vs_world_box <- renderUI({
    metric <- selected_metric()
    label <- metric_label(metric)
    filtered_values <- filtered_metric_series()
    global_values <- global_metric_series()

    if (length(filtered_values) == 0 || length(global_values) == 0) {
      return(kpi_card(
        paste("Vs world average:", label),
        "No data",
        bg = "#e9ecef"
      ))
    }

    filtered_avg <- mean(filtered_values, na.rm = TRUE)
    global_avg <- mean(global_values, na.rm = TRUE)
    diff <- filtered_avg - global_avg

    caption <- if (diff >= 0) {
      sprintf("%.1f above world average (%.1f)", diff, global_avg)
    } else {
      sprintf("%.1f below world average (%.1f)", abs(diff), global_avg)
    }

    bg <- if (abs(diff) < 1) "#dcfce7" else "#fef3c7"

    kpi_card(
      paste("Vs world average:", label),
      sprintf("%+.1f", diff),
      caption,
      bg = bg
    )
  })

  output$metric_coverage_box <- renderUI({
    metric <- selected_metric()
    label <- metric_label(metric)
    d <- filtered_df()

    n_available <- sum(!is.na(d[[metric]]))
    n_total <- nrow(d)

    if (n_total == 0) {
      return(kpi_card(
        paste("Data coverage:", label),
        "No data",
        bg = "#e9ecef"
      ))
    }

    pct <- 100 * n_available / n_total

    kpi_card(
      paste("Data coverage:", label),
      sprintf("%d/%d", n_available, n_total),
      sprintf("%.0f%% of selected countries have data", pct),
      bg = "#e0f2fe"
    )
  })
}

shinyApp(ui, server)