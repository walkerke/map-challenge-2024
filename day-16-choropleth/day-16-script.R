library(tidycensus)
library(tigris)
library(tidyverse)
options(tigris_use_cache = TRUE)

# Grab the data
us_wfh <- get_acs(
  geography = "puma",
  variables = "DP03_0024P",
  year = 2023,
  survey = "acs1",
  geometry = TRUE
) 

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
  add_fill_layer(
    id = "puma_wfh",
    source = us_wfh,
    fill_color = interpolate(
      column = "estimate",
      values = c(1.4, 9.4, 14.9, 22.2, 36.5),
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
    "% working from home by PUMA, 2023 1-year ACS",
    values = c("1.4%", "9.4%", "14.9%", "22.2%", "36.5%"),
    colors = viridisLite::plasma(5)
  )

wfh_map

htmlwidgets::saveWidget(wfh_map, "day-16-choropleth/index.html", selfcontained = FALSE)