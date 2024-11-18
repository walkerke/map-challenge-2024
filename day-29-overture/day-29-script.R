library(arrow)
# install_arrow()
library(sf)
library(dplyr)
library(tigris)
library(mapgl) 
options(tigris_use_cache = TRUE)

buildings <- open_dataset('s3://overturemaps-us-west-2/release/2024-10-23.0/theme=buildings?region=us-west-2')

sf_bbox <- counties(state = "CA", cb = TRUE, resolution = "20m") |> 
  filter(NAME == "San Francisco") |> 
  st_bbox() |> 
  as.vector()

sf_buildings <- buildings |>
  filter(bbox$xmin > sf_bbox[1],
         bbox$ymin > sf_bbox[2],
         bbox$xmax < sf_bbox[3],
         bbox$ymax < sf_bbox[4]) |>
  select(id, geometry, height) |> 
  collect() |>
  st_as_sf(crs = 4326) |> 
  mutate(height = ifelse(is.na(height), 8, height))

sf_map <- mapboxgl(
  style = mapbox_style("light"),
  center = c(-122.4657, 37.7548),
  zoom = 11.3,
  bearing = -60,
  pitch = 76
) |> 
  add_fill_extrusion_layer(
    id = "buildings",
    source = sf_buildings,
    fill_extrusion_height = get_column("height"),
    fill_extrusion_color = interpolate(
      column = "height",
      values = c(6, 54, 108, 163, 217, 326),
      stops = viridisLite::inferno(6, direction = -1)
    ),
    fill_extrusion_opacity = 0.5
  ) |> 
  add_legend(
    "Building heights in San Francisco",
    values = c("6m", "135m", "326m"),
    colors = viridisLite::inferno(6, direction = -1)
  )

sf_map

htmlwidgets::saveWidget(sf_map, "day-29-overture/index.html", selfcontained = FALSE)


