library(shiny)
library(bslib)
library(mapgl)
library(sf)
library(colourpicker)

pipelines <- st_read("ppl_arcs/ppl_arcs.shp")

ui <- page_navbar(
  theme = bs_theme(bootswatch = "cerulean"),
  title = "Blue Planet: Pipelines in the Gulf of Mexico",
  sidebar = sidebar(
    colourInput("color", "Select a pipeline color", value = "#0077be"),
    sliderInput("opacity", "Pipeline opacity", min = 0, max = 1, value = 0.7, step = 0.1),
    selectInput("status", "Pipeline Status", 
                choices = c("All", unique(pipelines$STATUS_COD)),
                selected = "All"),
    selectInput("prod_code", "Product Type",
                choices = c("All", unique(pipelines$PROD_CODE)),
                selected = "All"),
    sliderInput("size", "Minimum pipeline size", 
                min = 0, max = max(as.numeric(pipelines$PPL_SIZE_C), na.rm = TRUE), 
                value = 0, step = 1)
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
                     line_width = list("get", "PPL_SIZE_C"))
  })
  
  observeEvent(input$color, {
    maplibre_proxy("map") |>
      set_paint_property("pipelines", "line-color", input$color)
  })
  
  observeEvent(input$opacity, {
    maplibre_proxy("map") |>
      set_paint_property("pipelines", "line-opacity", input$opacity)
  })
  
observeEvent(input$status, {
  status_filter <- if(input$status != "All") {
    list("==", list("get", "STATUS_COD"), input$status)
  } else {
    list(">", 1, 0)  # This is always true, effectively no filter
  }
  maplibre_proxy("map") |> 
    set_filter("pipelines", status_filter)
})

observeEvent(input$prod_code, {
  prod_code_filter <- if(input$prod_code != "All") {
    list("==", list("get", "PROD_CODE"), input$prod_code)
  } else {
    list(">", 1, 0)  # This is always true, effectively no filter
  }
  
  maplibre_proxy("map") |> 
    set_filter("pipelines", prod_code_filter)
})

observeEvent(input$size, {
  size_filter <- list(">=", list("to-number", list("get", "PPL_SIZE_C")), input$size)
  
  maplibre_proxy("map") |> 
    set_filter("pipelines", size_filter)
})
}

shinyApp(ui, server)
