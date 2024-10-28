# Day 1: Points
# We'll make a circle cluster map of store brand locations across the 
# continental US with a custom symbol layer representing the store logo.
# Data are from Overture Maps.  Try anywhere in the world and any brand!
library(sf)
library(tidyverse)
library(arrow)
library(mapgl)

# Connect to the data
pois <- open_dataset('s3://overturemaps-us-west-2/release/2024-09-18.0/theme=places/type=place?region=us-west-2')

# Define the bounding box for the continental US
my_bbox <- c(-125, 24, -66, 50)

# Make the request.  We are querying a large area so this won't be fast.
# Speed up queries by reducing the bounding box size.
qt <- pois |> 
  filter(
    names$primary == "QuikTrip",
    bbox$xmin > my_bbox[1],
    bbox$ymin > my_bbox[2],
    bbox$xmax < my_bbox[3],
    bbox$ymax < my_bbox[4]
  ) |> 
  select(
    names, categories, confidence, geometry
  ) |> 
  collect() |> 
  st_as_sf(crs = 4326)

# Clean up the data
qt$name <- qt$names$primary
qt$category <- qt$categories$primary

qt_min <- dplyr::select(qt, name, category, confidence)

# Write to an RDS so we don't have to read in again
write_rds(qt_min, "day-1-points/qt_locations.rds")
qt_min <- read_rds("day-1-points/qt_locations.rds")

# Map with mapgl / Mapbox GL JS
qt_map <- mapboxgl(bounds = qt_min, 
  customAttribution = "Data source: Overture Maps") |> 
  # Add image to the sprite (logo I found on the web)
  add_image("qt-logo", "~/Downloads/QT.png") |>
  # Add a symbol layer with circle clustering using the image
  add_symbol_layer(
    id = "local_icons",
    source = qt_min,
    icon_image = "qt-logo",
    icon_size = 0.08,
    icon_allow_overlap = TRUE,
    cluster_options = cluster_options(
      color_stops = c("red", "grey", "black"),
      count_stops = c(0, 100, 300),
      circle_opacity = 0.8,
      circle_stroke_color = "white",
      circle_stroke_width = 2,
      text_color = "white"
    )
  )

qt_map

htmlwidgets::saveWidget(qt_map, "day-1-points/index.html")