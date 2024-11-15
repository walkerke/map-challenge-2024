library(shiny)
library(shinyMobile)
library(mapgl)

shinyApp(
  ui = f7Page(
    options = list(dark = TRUE, theme = "ios"),
    title = "mapgl example",
    f7SingleLayout(
      navbar = f7Navbar(title = "mapgl example"),
      toolbar = f7Toolbar(
        position = "bottom",
        f7Button("isochrone", "How far can I walk in 10 minutes?")
      ),
      mapboxglOutput("map", height = "100vh")
    )
  ),
  server = function(input, output) {
    output$map <- renderMapboxgl({
      mapboxgl() |> add_geolocate_control(
        show_user_heading = TRUE,
        track_user = TRUE
      )
    })

    observeEvent(input$isochrone, {
      mapboxgl_proxy("map")
    })

  }
)
