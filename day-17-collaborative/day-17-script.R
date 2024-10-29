library(shiny)
library(mapgl)
library(googlesheets4)
library(dplyr)
library(sf)
library(bslib)
library(googledrive)

# Set up Google Sheets authentication
options(
    gargle_oauth_cache = "google_auth",
    gargle_oauth_email = "kyle@walker-data.com"
)
SHEET_ID <- "1wiEXx2VZ3OPjuyr-i0e4OB96a1LgZIPAllADSdyW-nI"

# Functions for reading/writing locations
read_locations <- function() {
    tryCatch(
        {
            locations <- read_sheet(SHEET_ID)
            locations %>%
                mutate(
                    lng = as.numeric(lng),
                    lat = as.numeric(lat),
                    timestamp = as.POSIXct(timestamp)
                )
        },
        error = function(e) {
            data.frame(
                lng = numeric(),
                lat = numeric(),
                timestamp = as.POSIXct(character())
            )
        }
    )
}

append_location <- function(lng, lat) {
    new_location <- data.frame(
        lng = lng,
        lat = lat,
        timestamp = Sys.time()
    )
    sheet_append(SHEET_ID, new_location)
    read_locations()
}

# UI with bslib theming
ui <- page_fillable(
    theme = bs_theme(
        version = 5,
        bootswatch = "minty",
        primary = "#2c3e50",
        "enable-rounded" = TRUE,
        "body-bg" = "#f8f9fa"
    ),

    # Custom CSS
    tags$head(
        tags$style(HTML("
      .value-box {
        transition: transform 0.2s;
      }
      .value-box:hover {
        transform: translateY(-5px);
      }
      #submit {
        transition: all 0.3s;
      }
      #submit:hover {
        transform: scale(1.05);
      }
    "))
    ),

    # Layout
    layout_sidebar(
        sidebar = sidebar(
            title = "Visitor Map Controls",
            card(
                card_header("Instructions"),
                p("Drop a pin on the map to mark your location:"),
                tags$ol(
                    tags$li("Drag the marker to your location"),
                    tags$li("Or use the geolocate button (top-right) to find your position"),
                    tags$li("Click Submit to add your location")
                ),
                hr(),
                actionButton("submit", "Submit Location",
                    class = "btn-lg btn-primary w-100",
                    icon = icon("map-pin")
                )
            ),
            card(
                card_header("Statistics"),
                value_box(
                    title = "Total Visitors",
                    value = textOutput("visitorCount"),
                    showcase = icon("users"),
                    theme = "primary",
                    height = "100px"
                ),
                value_box(
                    title = "Last Visit",
                    value = textOutput("lastVisitor"),
                    showcase = icon("clock"),
                    theme = "secondary",
                    height = "100px"
                )
            )
        ),

        # Main panel with map
        card(
            full_screen = TRUE,
            card_header("Global Visitor Locations"),
            mapboxglOutput("map", height = "calc(100vh - 80px)")
        )
    )
)

server <- function(input, output, session) {
    # Reactive value for locations
    rv <- reactiveVal(read_locations())

    map_output <- reactive({
        locations <- rv()

        locations_sf <- st_as_sf(
            locations,
            coords = c("lng", "lat"),
            crs = 4326
        )

        mapboxgl(
            center = c(0, 0),
            zoom = 1
        ) %>%
            add_navigation_control() %>%
            add_geolocate_control() %>%
            add_markers(
                data = c(0, 0),
                draggable = TRUE,
                popup = "Drag me to your location!",
                marker_id = "visitor_marker"
            ) %>%
            add_circle_layer(
                id = "visitors",
                source = locations_sf,
                circle_color = "navy",
                circle_stroke_color = "white",
                circle_radius = 5,
                circle_stroke_width = 1,
                cluster_options = cluster_options(
                    max_zoom = 14,
                    cluster_radius = 50,
                    color_stops = c("#3498db", "#2ecc71", "#e74c3c"),
                    radius_stops = c(20, 30, 40),
                    count_stops = c(0, 10, 25),
                    circle_stroke_color = "#ffffff",
                    circle_stroke_width = 2,
                    circle_opacity = 0.8,
                    text_color = "#ffffff"
                ),
                popup = "timestamp",
                tooltip = "timestamp"
            )
    })

    # Render the map
    output$map <- renderMapboxgl({
        map_output()
    })


    # Handle submit button click
    observeEvent(input$submit, {
        marker_pos <- input$map_marker_visitor_marker
        if (!is.null(marker_pos)) {
            withProgress(
                message = "Submitting location...",
                value = 0.5,
                {
                    locations <- append_location(marker_pos$lng, marker_pos$lat)
                    rv(locations)
                    Sys.sleep(0.5) # Small delay for UX
                }
            )

            showNotification(
                "Location submitted successfully!",
                type = "message",
                duration = 3
            )
        }
    })

    # Update visitor count
    output$visitorCount <- renderText({
        locations <- rv()
        format(nrow(locations), big.mark = ",")
    })

    # Show last visitor time
    output$lastVisitor <- renderText({
        locations <- rv()
        if (nrow(locations) > 0) {
            last_time <- max(locations$timestamp)
            format(last_time, "%Y-%m-%d\n%H:%M")
        } else {
            "No visitors yet"
        }
    })
}

shinyApp(ui, server)
