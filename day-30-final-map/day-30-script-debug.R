library(shiny)
library(shinyMobile)
library(mapgl)
library(mapboxapi)

mb_token <- "pk.eyJ1Ijoia3dhbGtlcnRjdSIsImEiOiJMRk9JSmRvIn0.l1y2jHZ6IARHM_rA1-X45A"

shinyApp(
  ui = f7Page(
    options = list(dark = TRUE, theme = "ios"),
    title = "Example mobile app with mapgl",
    f7TabLayout(
      navbar = f7Navbar(title = "Example mobile app with mapgl"),
      f7Tabs(
        f7Tab(
          tabName = "Map",
          icon = f7Icon("map"),
          active = TRUE,
          f7Block(
            mapboxglOutput("map", height = "85vh")
          ),
          f7Block(
            position = "bottom",
            f7Button("isochrone", "How far can I walk in 10 minutes?")
          )
        ),
        f7Tab(
          tabName = "Debug",
          icon = f7Icon("info_circle"),
          f7Block(
            verbatimTextOutput("geolocateInfo"),
            verbatimTextOutput("geocode")
          )
        )
      )
    )
  ),
  server = function(input, output) {
    output$map <- renderMapboxgl({
      mapboxgl(access_token = mb_token) |> add_geolocate_control(
        show_user_heading = TRUE,
        track_user = TRUE
      ) |> 
        add_geocoder_control(position = "top-left", collapsed = TRUE,
    placeholder = " ")
    })

    output$geolocateInfo <- renderPrint({
      input$map_geolocate
    })

    output$geocode <- renderPrint({
      input$map_geocoder$result
    })

    observeEvent(input$isochrone, {

      if (!is.null(input$map_geolocate)) {
        iso <- mb_isochrone(
          location = c(input$map_center$lng,
                       input$map_center$lat),
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
