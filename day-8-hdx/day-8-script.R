library(tidyverse)
library(sf)
library(mapgl)
library(scales)
library(htmltools)

# Data sourced from https://data.humdata.org/dataset/idmc-event-data-for-yem

# Get the headers only
yemen_headers <- read_csv("day-8-hdx/event_data_yem.csv", n_max = 1)

yemen <- read_csv("day-8-hdx/event_data_yem.csv", skip = 2, col_names = FALSE)

colnames(yemen) <- colnames(yemen_headers)

yemen_sf <- yemen %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  filter(displacement_type == "Conflict") 


yemen_sf$popup <- sprintf(
  "<strong>Displacement Event</strong><br>
  <strong>Location:</strong> %s<br>
  <strong>Displaced People:</strong> %s<br>
  <strong>Date:</strong> %s<br>
  <strong>Description:</strong> %s<br>
  <a href='%s' target='_blank'>More Info</a>",
  yemen_sf$locations_name,
  format(yemen_sf$figure, big.mark = ","),
  format(as.Date(yemen_sf$displacement_date), "%B %d, %Y"),
  yemen_sf$description,
  yemen_sf$link
)

# Create the map
yemen_map <- mapboxgl(style = mapbox_style("light"), 
         bounds = yemen_sf,
         customAttribution = "<a href='https://data.humdata.org/dataset/idmc-event-data-for-yem'>Data source: HDX</a>") %>%
  add_circle_layer(
    id = "displacement-circles",
    source = yemen_sf,
    circle_color = "#FF4136",  
    circle_stroke_color = "#FF4136",
    circle_stroke_width = 0,
    circle_opacity = 0.7,
    circle_radius = interpolate(
      column = "figure",
      values = c(6, 15, 45, 90),
      stops = c(5, 10, 15, 20)  
    ),
    popup = "popup",
    hover_options = list(
      circle_stroke_color = "cyan",
      circle_stroke_width = 2
    )
  ) %>%
  add_categorical_legend(
    legend_title = HTML("<strong>Internal displacement due to<br>conflict events in Yemen</strong><br><small>HDX data, April 27 through August 10, 2024</small>"),
    values = c(6, 15, 45, 90),
    colors = "#FF4136",
    circular_patches = TRUE,
    sizes = c(5, 10, 15, 20),
    position = "top-right"
  )

yemen_map

htmlwidgets::saveWidget(yemen_map, "day-8-hdx/index.html", selfcontained = FALSE)
