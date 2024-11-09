library(shiny)
library(bslib)
library(mapgl)
library(sf)

pipelines <- st_read("ppl_arcs/ppl_arcs.shp")

ui <- page_navbar(
  theme = bs_theme(bootswatch = "cerulean"),
  title = "Pipelines in the Gulf of Mexico",
  sidebar = sidebar(
    colourInput("color", "Select a color",
                value = "blue"),
    sliderInput("slider", "Show BIR74 values above:",
                value = 248, min = 248, max = 21588)
  ),
  card(
    full_screen = TRUE,
    maplibreOutput("map")
  )
)

server <- function(input, output, session) {
  output$map <- renderMaplibre({
    maplibre(style = maptiler_style("ocean"),
             bounds = pipelines) |>
      add_line_layer(id = "pipelines",
                     source = pipelines,
                     line_color = "blue",
                     line_opacity = 0.5)
  })
}

shinyApp(ui, server)
