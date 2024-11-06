library(climateR)
library(terra)
library(sf)
library(dplyr)
library(mapgl)
library(tigris)

# Get Texas boundary
tx <- states(resolution = "20m") %>%
  filter(STUSPS == "TX")

# Fetch GridMET data
tmmx_data <- getGridMET(
  AOI = tx,
  varname = "tmmx",
  startDate = "2024-11-04",
  endDate = "2024-11-04"
)

# Convert to SpatRaster and calculate max temperature
tmmx_rast <- tmmx_data$daily_maximum_temperature

# Convert temperature from Kelvin to Fahrenheit
tmmx_rast <- (tmmx_rast - 273.15) * 9/5 + 32

# Convert raster to polygons
tmmx_polygons <- as.polygons(tmmx_rast, aggregate = FALSE)
# Convert to sf object
tmmx_sf <- st_as_sf(tmmx_polygons)

# Ensure the CRS matches Texas boundary
tmmx_sf <- st_transform(tmmx_sf, st_crs(tx))

# Clip to Texas boundary
tmmx_sf <- st_intersection(tmmx_sf, tx) %>%
  transmute(temp = round(tmmx_2024.11.04, 2)) %>%
  select(temp) 

# Create the map
heat_map <- mapboxgl(
  style = mapbox_style("light"),
  bounds = tx, 
  customAttribution = '<a href="https://www.climatologylab.org/gridmet.html" target="_blank">Data source: GridMET</a>'
) %>%
  add_fill_layer(
    id = "temperature",
    source = tmmx_sf,
    fill_color = mapgl::interpolate(
      column = "temp",
      values = seq(min(tmmx_sf$temp, na.rm = TRUE), max(tmmx_sf$temp, na.rm = TRUE), length.out = 100),
      stops = viridisLite::inferno(100)
    ),
    fill_opacity = 0.8,
    tooltip = "temp"
  ) %>%
  add_line_layer(
    id = "state_border",
    source = tx,
    line_color = "black",
    line_width = 2
  ) %>%
  add_continuous_legend(
    legend_title = "High temperature in Texas, Nov 4 2024",
    values = c(sprintf("%.1f°F", min(tmmx_sf$temp, na.rm = TRUE)), 
               sprintf("%.1f°F", max(tmmx_sf$temp, na.rm = TRUE))),
    colors = viridisLite::inferno(100)
  )

heat_map

# Save the map
htmlwidgets::saveWidget(heat_map, "day-25-heat/index.html", selfcontained = FALSE)


