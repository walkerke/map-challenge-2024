library(tidycensus)
library(tigris)
library(tidyverse)
options(tigris_use_cache = TRUE)

# Grab the data
us_wfh_data <- get_acs(
  geography = "tract",
  variables = "DP03_0024P",
  year = 2023,
  state = c(state.abb, "DC")
) 

# Get a lower-resolution tract file
us_tracts <- tracts(cb = TRUE, resolution = "5m") %>%
  select(GEOID)

us_wfh <- left_join(us_tracts, us_wfh_data, by = "GEOID")

# Interactive map with mapgl
library(mapgl)

# Format the popup
popup_content <- glue::glue(
  "<strong>{us_wfh$NAME}</strong><br>",
  "% working from home: {us_wfh$estimate}"
)

us_wfh$popup <- popup_content

# Build the interactive map
wfh_map <- mapboxgl(
  style = mapbox_style("light"), 
  center = c(-98.5795, 39.8283), 
  zoom = 3
) %>%
  add_source(
    data = us_wfh, 
    tolerance = 0,
    id = "us_tracts"
  ) %>%
  add_fill_layer(
    id = "puma_wfh",
    source = "us_tracts",
    fill_color = interpolate(
      column = "estimate",
      values = c(0, 5, 10, 25, 50),
      stops = viridisLite::plasma(5),
      na_color = "lightgrey"
    ),
    fill_opacity = 0.7,
    popup = "popup", 
    hover_options = list(
      fill_color = "cyan",
      fill_opacity = 1
    )
  ) %>%
  add_legend(
    "% working from home by tract, 2023 5-year ACS",
    values = c("0%", "5%", "10%", "25%", "50%+"),
    colors = viridisLite::plasma(5)
  )

wfh_map

htmlwidgets::saveWidget(wfh_map, "day-16-choropleth/index.html", selfcontained = FALSE)