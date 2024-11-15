library(shiny)
library(mapgl)
library(magrittr)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body, html { height: 100%; margin: 0; padding: 0; }
      #map { position: absolute; top: 0; bottom: 0; left: 0; right: 0; }
    "))
  ),
  mapboxglOutput("map", height = "100vh"),
  absolutePanel(
    top = 10, right = 10, width = 250,
    draggable = TRUE,
    wellPanel(
      style = "background: rgba(255, 255, 255, 0.8);",
      p("Display administrative boundaries consistent with the following worldview:"),
      radioButtons("worldview", "",
                   choices = list("China" = "CN",
                                  "India" = "IN",
                                  "Japan" = "JP",
                                  "United States" = "US"),
                   selected = "US")
    )
  )
)

server <- function(input, output, session) {
  output$map <- renderMapboxgl({
    mapboxgl(
      style = mapbox_style("light"),
      center = c(88, 26),
      zoom = 4,
      access_token = "YOUR_TOKEN_GOES_HERE"
    )
  })

  observe({
    mapboxgl_proxy("map") %>%
      set_filter(
        layer_id = "admin-0-boundary-disputed",
        filter = list(
          "all",
          list("==", list("get", "disputed"), "true"),
          list("==", list("get", "admin_level"), 0),
          list("==", list("get", "maritime"), "false"),
          list("match", list("get", "worldview"), list("all", input$worldview), TRUE, FALSE)
        )
      ) %>%
      set_filter(
        layer_id = "admin-0-boundary",
        filter = list(
          "all",
          list("==", list("get", "admin_level"), 0),
          list("==", list("get", "disputed"), "false"),
          list("==", list("get", "maritime"), "false"),
          list("match", list("get", "worldview"), list("all", input$worldview), TRUE, FALSE)
        )
      ) %>%
      set_filter(
        layer_id = "admin-0-boundary-bg",
        filter = list(
          "all",
          list("==", list("get", "admin_level"), 0),
          list("==", list("get", "maritime"), "false"),
          list("match", list("get", "worldview"), list("all", input$worldview), TRUE, FALSE)
        )
      )
  })
}

shinyApp(ui, server)
