# ===============================
# Cloud Seeding & Climate Analytics Dashboard
# ===============================

# ---- Libraries ----
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(tidyr)
library(GGally)

# ---- Load Data ----
data <- read.csv("synthetic_india_cloud_seeding_weather.csv")

# ---- Data Cleaning ----
data <- data %>%
  mutate(
    State  = as.factor(State),
    Season = as.factor(Season),
    Year   = as.integer(Year),
    CSI = 0.4 * Humidity_pct +
      0.4 * CloudCover_pct -
      0.2 * Rainfall_mm
  )

# ===============================
# UI
# ===============================
ui <- dashboardPage(
  dashboardHeader(title = "Cloud Seeding & Climate Analytics"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Rainfall Analysis", tabName = "rainfall", icon = icon("cloud-rain")),
      menuItem("Cloud Seeding Index", tabName = "csi", icon = icon("seedling")),
      menuItem("Multivariate Analysis", tabName = "multi", icon = icon("project-diagram")),
      
      hr(),
      
      selectInput(
        "state",
        "Select State",
        choices = c("All", levels(data$State)),
        selected = "All"
      ),
      
      selectInput(
        "season",
        "Select Season",
        choices = c("All", levels(data$Season)),
        selected = "All"
      ),
      
      sliderInput(
        "year",
        "Select Year Range",
        min(data$Year),
        max(data$Year),
        value = c(min(data$Year), max(data$Year)),
        sep = ""
      )
    )
  ),
  
  dashboardBody(
    tabItems(
      
      # ---------------------------
      # OVERVIEW TAB
      # ---------------------------
      tabItem(
        tabName = "overview",
        
        fluidRow(
          valueBoxOutput("avgRain", width = 4),
          valueBoxOutput("avgCSI", width = 4),
          valueBoxOutput("avgTemp", width = 4)
        ),
        
        fluidRow(
          box(
            title = "Rainfall Trend Over Years",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            plotOutput("rainTrend", height = 300)
          )
        )
      ),
      
      # ---------------------------
      # RAINFALL TAB
      # ---------------------------
      tabItem(
        tabName = "rainfall",
        
        fluidRow(
          box(
            title = "State-wise Rainfall Distribution",
            width = 6,
            status = "info",
            plotOutput("rainBox", height = 300)
          ),
          
          box(
            title = "State-Year Rainfall Heatmap",
            width = 6,
            status = "info",
            plotOutput("rainHeat", height = 300)
          )
        )
      ),
      
      # ---------------------------
      # CSI TAB
      # ---------------------------
      tabItem(
        tabName = "csi",
        
        fluidRow(
          box(
            title = "Cloud Seeding Feasibility Index by State",
            width = 12,
            status = "success",
            plotOutput("csiPlot", height = 350)
          )
        )
      ),
      
      # ---------------------------
      # MULTIVARIATE TAB
      # ---------------------------
      tabItem(
        tabName = "multi",
        
        fluidRow(
          box(
            title = "Correlation & Dependency Analysis",
            width = 12,
            status = "warning",
            plotOutput("pairsPlot", height = 500)
          )
        )
      )
    )
  )
)

# ===============================
# SERVER
# ===============================
server <- function(input, output) {
  
  # ---- Reactive Filtered Data ----
  filtered_data <- reactive({
    df <- data %>%
      filter(Year >= input$year[1], Year <= input$year[2])
    
    if (input$state != "All") {
      df <- df %>% filter(State == input$state)
    }
    
    if (input$season != "All") {
      df <- df %>% filter(Season == input$season)
    }
    
    df
  })
  
  # ---- KPI Boxes ----
  output$avgRain <- renderValueBox({
    valueBox(
      round(mean(filtered_data()$Rainfall_mm), 1),
      "Avg Rainfall (mm)",
      icon = icon("cloud"),
      color = "blue"
    )
  })
  
  output$avgCSI <- renderValueBox({
    valueBox(
      round(mean(filtered_data()$CSI), 1),
      "Avg CSI",
      icon = icon("seedling"),
      color = "green"
    )
  })
  
  output$avgTemp <- renderValueBox({
    valueBox(
      round(mean(filtered_data()$Temperature_C), 1),
      "Avg Temperature (°C)",
      icon = icon("temperature-high"),
      color = "orange"
    )
  })
  
  # ---- Rainfall Trend ----
  output$rainTrend <- renderPlot({
    filtered_data() %>%
      group_by(Year) %>%
      summarise(AvgRain = mean(Rainfall_mm)) %>%
      ggplot(aes(Year, AvgRain)) +
      geom_line(linewidth = 1, color = "steelblue") +
      geom_point() +
      theme_minimal() +
      labs(x = "Year", y = "Rainfall (mm)")
  })
  
  # ---- Rainfall Boxplot ----
  output$rainBox <- renderPlot({
    ggplot(filtered_data(), aes(State, Rainfall_mm)) +
      geom_boxplot(fill = "skyblue") +
      coord_flip() +
      theme_minimal() +
      labs(x = "State", y = "Rainfall (mm)")
  })
  
  # ---- Heatmap ----
  output$rainHeat <- renderPlot({
    filtered_data() %>%
      group_by(State, Year) %>%
      summarise(AvgRain = mean(Rainfall_mm)) %>%
      ggplot(aes(Year, State, fill = AvgRain)) +
      geom_tile() +
      scale_fill_gradient(low = "yellow", high = "blue") +
      theme_minimal()
  })
  
  # ---- CSI Plot ----
  output$csiPlot <- renderPlot({
    filtered_data() %>%
      group_by(State) %>%
      summarise(AvgCSI = mean(CSI)) %>%
      ggplot(aes(State, AvgCSI)) +
      geom_col(fill = "darkgreen") +
      coord_flip() +
      theme_minimal() +
      labs(x = "State", y = "CSI")
  })
  
  # ---- Multivariate Plot ----
  output$pairsPlot <- renderPlot({
    GGally::ggpairs(
      filtered_data()[, c(
        "Rainfall_mm",
        "Humidity_pct",
        "CloudCover_pct",
        "Temperature_C",
        "Pressure_hPa",
        "WindSpeed_mps"
      )]
    )
  })
}

# ===============================
# RUN APP
# ===============================
shinyApp(ui, server)
