library(idbr)
library(mapgl)
library(dplyr)

tfr <- get_idb(
  country = "all",
  year = 2024,
  variables = "tfr",
  geometry = TRUE
) 

tfr_map <- mapboxgl(style = carto_style("positron")) |> 
  add_fill_layer(
    id = "tfr",
    source = tfr,
    fill_color = interpolate(
      column = "tfr",
      values = c(1, 7),
      stops = c("thistle", "indigo")
    ),
    tooltip = "tfr"
  ) |> 
  add_navigation_control() |> 
  add_legend(
    legend_title = "Total fertility rate, 2024",
    values = c(1, 7),
    colors = c("thistle",
    "indigo")
  )

tfr_map

htmlwidgets::saveWidget(tfr_map, "day-14-world-map/index.html", selfcontained = FALSE)