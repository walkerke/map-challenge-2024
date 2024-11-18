# ... existing code ...

ui <- page_navbar(
  theme = bs_theme(bootswatch = "cerulean"),
  title = "Blue Planet: Pipelines in the Gulf of Mexico",
  sidebar = sidebar(
    colourInput("color", "Select a pipeline color", value = "#0077be"),
    sliderInput("opacity", "Pipeline opacity", min = 0, max = 1, value = 0.7, step = 0.1),
    selectInput("status", "Pipeline Status", 
                choices = c("All", unique(pipelines$STATUS_CODE)),
                selected = "All"),
    selectInput("prod_code", "Product Type",
                choices = c("All", unique(pipelines$PROD_CODE)),
                selected = "All"),
    sliderInput("size", "Minimum pipeline diameter (inches)", 
                min = 0, max = max(as.numeric(gsub("[^0-9.]", "", pipelines$PPL_SIZE_CODE)), na.rm = TRUE), 
                value = 0, step = 0.5),
    selectInput("aprv_code", "Approval Type",
                choices = c("All", unique(pipelines$APRV_CODE)),
                selected = "All")
  ),
  card(
    full_screen = TRUE,
    maplibreOutput("map")
  )
)

server <- function(input, output, session) {
  output$map <- renderMaplibre({
    maplibre(style = maptiler_style("ocean"), bounds = pipelines, 
             customAttribution = '<a href="https://www.data.boem.gov/Main/Mapping.aspx">Data source: BOEM</a>') |>
      add_line_layer(id = "pipelines",
                     source = pipelines,
                     line_color = "#0077be",
                     line_opacity = 0.7,
                     line_width = list("get", "SEG_LENGTH"))
  })
  
  # ... existing code ...

  observeEvent(input$status, {
    status_filter <- if(input$status != "All") {
      list("==", list("get", "STATUS_CODE"), input$status)
    } else {
      list(">", 1, 0)  # This is always true, effectively no filter
    }
    maplibre_proxy("map") |> 
      set_filter("pipelines", status_filter)
  })

  observeEvent(input$size, {
    size_filter <- list(">=", list("to-number", list("get", "PPL_SIZE_CODE")), input$size)
    
    maplibre_proxy("map") |> 
      set_filter("pipelines", size_filter)
  })

  observeEvent(input$aprv_code, {
    aprv_code_filter <- if(input$aprv_code != "All") {
      list("==", list("get", "APRV_CODE"), input$aprv_code)
    } else {
      list(">", 1, 0)  # This is always true, effectively no filter
    }
    
    maplibre_proxy("map") |> 
      set_filter("pipelines", aprv_code_filter)
  })
}

# ... existing code ...