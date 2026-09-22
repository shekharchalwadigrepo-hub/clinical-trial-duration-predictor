# ============================================================
# app/app.R
# Shiny Dashboard - Clinical Trial Duration Predictor
# ============================================================

library(shiny)
library(bslib)
library(tidyverse)
library(tidymodels)

# Load helper functions
source("R/04_utils.R")

# Load model and data once when the app starts
model <- load_best_model()
clean_data <- load_clean_data()

# Get available phases from the actual data
available_phases <- sort(unique(clean_data$phase_clean))

# ----------------------------------------------------------
# UI
# ----------------------------------------------------------
ui <- page_navbar(
  title = "Clinical Trial Duration Predictor",
  theme = bs_theme(bootswatch = "flatly", primary = "#2C3E50"),
  
  # -------------------- Predict Tab --------------------
  nav_panel(
    title = "Predict",
    layout_sidebar(
      sidebar = sidebar(
        title = "Trial Characteristics",
        width = 320,
        
        selectInput(
          "phase", "Phase",
          choices = available_phases,
          selected = available_phases[1]
        ),
        
        selectInput(
          "sponsor", "Sponsor Type",
          choices = c("Industry", "Other"),
          selected = "Industry"
        ),
        
        numericInput(
          "enrollment", "Number of Participants",
          value = 200, min = 10, max = 10000, step = 10
        ),
        
        numericInput(
          "n_sites", "Number of Sites",
          value = 25, min = 1, max = 500, step = 1
        ),
        
        numericInput(
          "start_year", "Start Year",
          value = 2020, min = 2005, max = 2025, step = 1
        ),
        
        actionButton("predict_btn", "Predict Duration", class = "btn-primary w-100")
      ),
      
      card(
        card_header("Prediction Result"),
        card_body(
          uiOutput("prediction_result"),
          br(),
          plotOutput("duration_distribution", height = "350px")
        )
      )
    )
  ),
  
  # -------------------- Data Overview Tab --------------------
  nav_panel(
    title = "Data Overview",
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Duration Distribution"),
        plotOutput("hist_duration")
      ),
      card(
        card_header("Duration by Phase"),
        plotOutput("boxplot_phase")
      )
    ),
    card(
      card_header("Summary Statistics"),
      verbatimTextOutput("summary_text")
    )
  ),
  
  # -------------------- About Tab --------------------
  nav_panel(
    title = "About",
    card(
      card_body(
        h3("About this Project"),
        
        h4("What is this prediction used for?"),
        p("This tool predicts how long a clinical trial is likely to take from start to completion. 
           Knowing the expected duration helps in better planning of time, budget, and resources."),
        
        h4("Who can use this prediction and what do they need to enter?"),
        
        tags$table(
          class = "table table-bordered table-striped",
          tags$thead(
            tags$tr(
              tags$th("User Group"),
              tags$th("What they need to enter"),
              tags$th("How they benefit")
            )
          ),
          tags$tbody(
            tags$tr(
              tags$td(strong("Clinical Trial Managers")),
              tags$td("Phase, Enrollment, Number of Sites, Sponsor Type, Start Year"),
              tags$td("Plan more realistic study timelines")
            ),
            tags$tr(
              tags$td(strong("Pharmaceutical & Biotech Companies")),
              tags$td("Phase, Enrollment, Number of Sites, Sponsor Type, Start Year"),
              tags$td("Estimate project timelines and allocate budget better")
            ),
            tags$tr(
              tags$td(strong("CROs")),
              tags$td("Phase, Enrollment, Number of Sites, Sponsor Type, Start Year"),
              tags$td("Give better and more realistic time estimates to clients")
            ),
            tags$tr(
              tags$td(strong("Biostatisticians & Data Scientists")),
              tags$td("Phase, Enrollment, Number of Sites, Sponsor Type, Start Year"),
              tags$td("Understand which factors influence trial duration")
            ),
            tags$tr(
              tags$td(strong("Students & Researchers")),
              tags$td("Any combination of the above inputs"),
              tags$td("Learn how real clinical trial data is used in data science")
            )
          )
        ),
        
        h4("Conclusion"),
        p("This Shiny app shows how publicly available clinical trial data can be turned into a useful prediction tool. 
           By using historical data from ClinicalTrials.gov, the model provides a simple estimate of how long a new trial might take. 
           While the prediction is not perfect, it gives a helpful starting point for planning and decision-making in clinical research."),
        
        hr(),
        p(em("Built as a portfolio project combining Clinical Trials domain knowledge, R Shiny, and Data Science."))
      )
    )
  )
)

# ----------------------------------------------------------
# Server
# ----------------------------------------------------------
server <- function(input, output, session) {
  
  # Reactive prediction
  prediction <- eventReactive(input$predict_btn, {
    new_data <- make_prediction_input(
      phase = input$phase,
      sponsor_type = input$sponsor,
      enrollment = input$enrollment,
      n_sites = input$n_sites,
      start_year = input$start_year
    )
    
    pred <- predict_duration(model, new_data)
    pred$predicted_duration
  })
  
  # Display prediction result
  output$prediction_result <- renderUI({
    req(prediction())
    
    months <- prediction()
    years  <- months / 12
    
    div(
      style = "text-align: center; padding: 20px;",
      h2(style = "color: #18BC9C; font-weight: 700;",
         paste0(round(months, 1), " months")),
      h4(paste0("≈ ", round(years, 1), " years")),
      p(class = "text-muted", "Predicted duration based on the selected trial characteristics")
    )
  })
  
  # Distribution plot with prediction line
  output$duration_distribution <- renderPlot({
    req(prediction())
    
    ggplot(clean_data, aes(x = duration_months)) +
      geom_histogram(bins = 40, fill = "#3498DB", alpha = 0.7, color = "white") +
      geom_vline(xintercept = prediction(), color = "#E74C3C", linewidth = 1.3, linetype = "dashed") +
      annotate("text", x = prediction(), y = Inf, 
               label = " Prediction", vjust = 2, hjust = -0.1, color = "#E74C3C") +
      labs(
        title = "Where does this prediction sit in the historical distribution?",
        x = "Trial Duration (months)",
        y = "Number of Trials"
      ) +
      theme_minimal(base_size = 14)
  })
  
  # Histogram of all durations
  output$hist_duration <- renderPlot({
    ggplot(clean_data, aes(x = duration_months)) +
      geom_histogram(bins = 40, fill = "#3498DB", alpha = 0.8, color = "white") +
      labs(x = "Duration (months)", y = "Count") +
      theme_minimal(base_size = 13)
  })
  
  # Boxplot by phase
  output$boxplot_phase <- renderPlot({
    ggplot(clean_data, aes(x = phase_clean, y = duration_months, fill = phase_clean)) +
      geom_boxplot(alpha = 0.8) +
      labs(x = NULL, y = "Duration (months)") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "none")
  })
  
  # Summary text
  output$summary_text <- renderPrint({
    summarise_trials(clean_data)
  })
}

# ----------------------------------------------------------
# Run the application
# ----------------------------------------------------------
shinyApp(ui, server)


