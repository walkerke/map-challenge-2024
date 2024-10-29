library(mapgl)
library(tigris)
library(tidyverse)
library(sf)
options(tigris_use_cache = TRUE)

us_places <- places(cb = TRUE, year = 2023)

pen <- filter(us_places, str_detect(NAME, "Pen|pen")) |> 
  st_centroid()

# Add the "pencil" map style to your Mapbox account, then reference the style from Mapbox Studio
pen_map <- mapboxgl(style = "mapbox://styles/kwalkertcu/cm2kevzl7005401p7ghz2a621",
         bounds = pen, height = "100vh") |> 
  add_image("pen-icon", "day-10-pen-and-paper/pen-icon.png") |> 
  add_symbol_layer(
    id = "pens",
    source = pen,
    icon_image = "pen-icon",
    icon_allow_overlap = TRUE,
    icon_size = 0.4,
    tooltip = "NAME"
  )

pen_map

htmlwidgets::saveWidget(pen_map, "day-10-pen-and-paper/index.html")