library(mapboxapi)
library(mapgl)

# Calculate a route between two locations with mapboxapi
route <- mb_directions(
  origin = "TCU, Fort Worth TX 76129",
  destination = "Baylor University, Waco TX 76706",
  overview = "full"
)

# Visualize the route with an interpolated line gradient
# representing the colors of the Universities
rivalry_map <- mapboxgl(
  bounds = route,
  style = mapbox_style("light")
) |>
  add_source(
    id = "route_source",
    data = route,
    lineMetrics = TRUE
  ) |>
  add_line_layer(
    id = "route",
    source = "route_source",
    line_width = 14,
    line_gradient = interpolate(
      property = "line-progress",
      values = seq(0, 1, 1/3),
      stops = c("purple", "grey", "yellow", "green")
    ),
    line_z_offset = interpolate(
      property = "line-progress",
      values = c(0, 0.5, 1),
      stops = c(0, 20000, 0)
    )
  )

rivalry_map

htmlwidgets::saveWidget(rivalry_map, "day-2-lines/index.html", selfcontained = FALSE)
