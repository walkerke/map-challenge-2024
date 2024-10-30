library(lehdr)
library(sf)
library(mapgl)
library(tigris)
library(dplyr)
library(h3) # remotes::install_github("crazycapivara/h3-r")
options(tigris_use_cache = TRUE)
sf_use_s2(FALSE)

# Get jobs data by block for California, subset for health care
la_wac <- grab_lodes(
  state = "ca",
  year = 2021,
  lodes_type = "wac",
  agg_geo = "block",
  use_cache = TRUE
) %>%
  select(GEOID = w_geocode, healthcare = CNS16)

# Grab LA County blocks, convert to points
la_blocks <- blocks("CA", "Los Angeles", year = 2024) %>%
  select(GEOID = GEOID20) %>%
  st_point_on_surface()

# Join the block points and WAC data
la_wac_geo <- left_join(la_blocks, la_wac, by = "GEOID") %>%
  st_transform(4326)

# Get h3 level 8 hexagons for the region
la_county <- counties("CA", cb = TRUE) %>%
  filter(NAME == "Los Angeles")

hexagons <- polyfill(la_county, res = 7)

hex_sf <- h3_to_geo_boundary_sf(hexagons)

# Join the data
hex_medical_jobs <- st_join(hex_sf, la_wac_geo) %>%
  st_drop_geometry() %>% # For calculation speed
  summarize(health_jobs = sum(healthcare, na.rm = TRUE), .by = h3_index)

hex_jobs_sf <- left_join(hex_sf, hex_medical_jobs, by = "h3_index")

# Map in 3D
hex_map <- mapboxgl(style = mapbox_style("light"), 
customAttribution = "Data source: <a href='https://github.com/jamgreen/lehdr'>LODES / lehdr R pacakge</a>") %>%
  fit_bounds(hex_jobs_sf, pitch = 60, bearing = 30) %>%
  add_fill_extrusion_layer(
    id = "health-jobs",
    source = hex_jobs_sf,
    fill_extrusion_color = interpolate(
      column = "health_jobs",
      values = c(0, 100, 1000, 5000, 19706),
      stops = c("#f7fbff", "#deebf7", "#9ecae1", "#3182bd", "#08519c")
    ),
    fill_extrusion_height = interpolate(
      column = "health_jobs",
      values = c(0, 20000),
      stops = c(0, 20000)  # Adjust max height as needed
    ),
    fill_extrusion_opacity = 0.8,
    tooltip = "health_jobs",
    hover_options = list(
      fill_extrusion_color = "yellow"
    )
  ) %>%
  add_legend(
    legend_title = "Health Care Jobs, 2021 LODES<br><span style='font-size: 80%; font-weight: normal;'>Los Angeles County, California</span>",
    colors = c("#f7fbff", "#deebf7", "#9ecae1", "#3182bd", "#08519c"),
    values = c("0", "100", "1k", "5k", "20k")
  )

hex_map

htmlwidgets::saveWidget(hex_map, "day-4-hexagons/index.html", selfcontained = FALSE)