library(mapgl)

mapboxgl(
  style = mapbox_style("light"),
  center = c(75.3412, 33.2778),  
  zoom = 6,
  worldview = "IN"
)
