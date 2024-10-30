library(mapgl)

in_wv_map <- mapboxgl(
  style = mapbox_style("light"),
  center = c(75.3412, 33.2778),  
  zoom = 6,
  worldview = "IN"
)

in_wv_map

htmlwidgets::saveWidget(in_wv_map, "day-21-conflict/index.html", selfcontained = FALSE)
