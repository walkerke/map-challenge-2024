library(mapgl)

# Choose a font from here: https://docs.mapbox.com/mapbox-gl-js/guides/styles/#mapbox-standard-1
mont_map <- mapboxgl(
  center = c(14.4378, 50.0755), 
  zoom = 14
) |> 
  set_config_property("basemap", "font", "Montserrat")

mont_map

htmlwidgets::saveWidget(mont_map, "day-19-typography/index.html")
