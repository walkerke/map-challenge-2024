library(tigris)
library(mapgl)
library(sf)
library(dplyr)
options(tigris_use_cache = TRUE)

manhattan_blocks <- blocks(year = 2020, state = "NY", county = "New York") %>%
  dplyr::select(GEOID20, POP20) %>%
  erase_water() %>%
  dplyr::filter(sf::st_is(.$geometry, c("POLYGON", "MULTIPOLYGON")))

manhattan_3d <- mapboxgl(center = c(-73.9652, 40.7804),
         zoom = 11,
         pitch = 45,
         bearing = -74) %>%
  add_fill_extrusion_layer(
    id = "manhattan",
    source = manhattan_blocks,
    fill_extrusion_height = get_column("POP20"),
    fill_extrusion_opacity = 0.8,
    fill_extrusion_color = interpolate(
      column = "POP20",
      values = c(0, max(manhattan_blocks$POP20, na.rm = TRUE)),
      stops = c("pink", "maroon")
    ),
    tooltip = "POP20",
    hover_options = list(
      fill_extrusion_color = "lightgreen"
    )
  ) %>%
  add_legend(
    legend_title = "Block population in Manhattan, 2020",
    values = c(0, max(manhattan_blocks$POP20, na.rm = TRUE)),
    colors = c("pink", "maroon")
  )

manhattan_3d

htmlwidgets::saveWidget(manhattan_3d, "day-18-3D/index.html", selfcontained = FALSE)



