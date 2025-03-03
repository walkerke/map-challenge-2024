library(climateR)
library(terra)
library(sf)
library(dplyr)
library(mapgl) # remotes::install_github("walkerke/mapgl")
library(tigris)

# Get Texas boundary
tx <- states(resolution = "20m") %>%
  filter(STUSPS == "TX") %>%
  st_transform(4326)

# Fetch GridMET data
tmmx_data <- getGridMET(
  AOI = tx,
  varname = "tmmx",
  startDate = "2025-02-19",
  endDate = "2025-02-19"
)

tmmx_rast <- tmmx_data$daily_maximum_temperature %>%
  mask(tx)

# Convert temperature from Kelvin to Fahrenheit
tmmx_rast <- (tmmx_rast - 273.15) * 9/5 + 32

# Create the map
heat_map <- mapboxgl(
  style = mapbox_style("light"),
  bounds = tx,
  customAttribution = '<a href="https://www.climatologylab.org/gridmet.html" target="_blank">Data source: GridMET</a>'
) %>%
  add_image_source(
    id = "tmmx",
    data = tmmx_rast,
    colors = viridisLite::turbo(100)
  ) %>%
  add_raster_layer(
    id = "tmmx",
    source = "tmmx",
    raster_opacity = 0.8
  ) %>%
  add_continuous_legend(
    legend_title = "High temperature in Texas, Feb 19 2025",
    values = c(sprintf("%.1f°F", min(values(tmmx_rast), na.rm = TRUE)),
               sprintf("%.1f°F", max(values(tmmx_rast), na.rm = TRUE))),
    colors = viridisLite::turbo(100)
  )

heat_map

htmlwidgets::saveWidget(heat_map, "day-25-heat/day-25-heat-map-raster.html", selfcontained = TRUE)


