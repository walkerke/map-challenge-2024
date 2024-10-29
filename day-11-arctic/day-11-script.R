library(mapgl)
library(sf)
library(dplyr)
library(rnaturalearth)

# Load populated places data from Natural Earth
populated_places <- ne_download(
  scale = 10,
  type = "populated_places_simple"
)

# Find places north of the Arctic Circle
arctic_places <- filter(populated_places, latitude > 66.5) |> 
  transmute(place_name = paste(name, adm0name, sep = ", "))

arctic_map <- mapboxgl(style = mapbox_style("standard-satellite"), center = c(0, 90)) |> 
  add_markers(
    data = arctic_places, 
    color = "lightblue",
    popup = "place_name"
  )

arctic_map

htmlwidgets::saveWidget(arctic_map, "day-11-arctic/index.html")