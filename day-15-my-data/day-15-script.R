library(shiny)
library(mapgl)
library(mapboxapi)

access_token <- "YOUR_TOKEN_GOES_HERE"

# Define locations
locations <- list(
  "Lawrence, KS" = mapboxapi::mb_geocode("Lawrence, KS", access_token = access_token),
  "Salem, OR" = mapboxapi::mb_geocode("Salem, OR", access_token = access_token),
  "Salt Lake City, UT" = mapboxapi::mb_geocode("Salt Lake City, UT", access_token = access_token),
  "Corvallis, OR" = mapboxapi::mb_geocode("Corvallis, OR", access_token = access_token),
  "Eugene, OR" = mapboxapi::mb_geocode("Eugene, OR", access_token = access_token),
  "Eden Prairie, MN" = mapboxapi::mb_geocode("Eden Prairie, MN", access_token = access_token),
  "Bayside, NY" = mapboxapi::mb_geocode("Bayside, NY", access_token = access_token),
  "Fort Worth, TX" = mapboxapi::mb_geocode("Fort Worth, TX", access_token = access_token)
)

ui <- fluidPage(
  titlePanel("Cities where I've lived"),
  sidebarLayout(
    sidebarPanel(
      actionButton("play_button", "Play Tour"),
      actionButton("stop_button", "Stop Tour")
    ),
    mainPanel(
      mapboxglOutput("map")
    )
  )
)

server <- function(input, output, session) {

  # Reactive value to store current location index
  current_location <- reactiveVal(1)

  # Reactive value to control tour play/stop
  is_playing <- reactiveVal(FALSE)

  # Render initial map
  output$map <- renderMapboxgl({
    mapboxgl(access_token = access_token) |>
      set_view(center = c(locations[[1]][1], locations[[1]][2]), zoom = 10)
  })

  # Observer for play button
  observeEvent(input$play_button, {
    is_playing(TRUE)
    for (i in current_location():length(locations)) {
      if (is_playing()) {
        current_location(i)
        mapboxgl_proxy("map") |>
          fly_to(center = c(locations[[i]][1], locations[[i]][2]), zoom = 10)

        # Wait for the fly_to animation to complete (approx. 2 seconds)
        Sys.sleep(2)

        # Pause for 3 seconds after landing
        for (j in 1:3) {
          if (!is_playing()) break
          Sys.sleep(1)
      }
      } else {
        break
    }
    }
    is_playing(FALSE)
  })

  # Observer for stop button
  observeEvent(input$stop_button, {
    is_playing(FALSE)
  })
}

shinyApp(ui, server)
