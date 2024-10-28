library(mapgl)
library(tigris)
library(tidyverse)
library(sf)

us_places <- places(cb = TRUE, year = 2023)

pen <- filter(us_places, str_detect(NAME, "Pen|pen")) |> 
  st_centroid()

mapboxgl(style = "mapbox://styles/kwalkertcu/cm2kevzl7005401p7ghz2a621",
         bounds = pen) |> 
  add_image("pen-icon", "day-10-pen-and-paper/pen-icon.png") |> 
  add_symbol_layer(
    id = "pens",
    source = pen,
    icon_image = "pen-icon",
    icon_allow_overlap = TRUE,
    icon_size = 0.4,
    tooltip = "NAME"
  )