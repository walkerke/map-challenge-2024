library(shiny)
library(shinyMobile)
library(mapgl)
library(mapboxapi)

mb_token <- "YOUR_TOKEN_HERE"

shinyApp(
  ui = f7Page(
    options = list(dark = TRUE, theme = "ios"),
    title = "Example mobile app with mapgl",
    f7Navbar(title = "Example mobile app with mapgl"),
    f7Block(
      mapboxglOutput("map", height = "60vh")
    ),
    f7Block(
      position = "bottom",
      f7Button(
        inputId = "isochrone",
        label = "How far can I walk in 10 minutes?",
        color = "blue",
        fill = TRUE,
        rounded = TRUE
      )
    )
    ),
  server = function(input, output) {
    output$map <- renderMapboxgl({
      mapboxgl(access_token = mb_token) |> add_geolocate_control(
        show_user_heading = TRUE,
        track_user = TRUE
      )
    })

    output$geolocateInfo <- renderPrint({
      input$map_geolocate
    })


    observeEvent(input$isochrone, {

      if (!is.null(input$map_geolocate)) {
        iso <- mb_isochrone(
          location = c(input$map_geolocate$coords$longitude,
                       input$map_geolocate$coords$latitude),
          time = 10,
          profile = "walking",
          access_token = mb_token
        )

        mapboxgl_proxy("map") |>
          add_fill_layer(
            id = "iso",
            source = iso,
            fill_opacity = 0.5
          ) |>
          fit_bounds(iso, animate = TRUE)
      } else {
        f7Dialog(
          title = "Warning",
          text = "Please geolocate yourself first before using this feature.",
          type = "alert"
        )
      }
    })

  }
)
