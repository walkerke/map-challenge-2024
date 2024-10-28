library(tidyverse)
# Data source: 
# https://datarepository.movebank.org/entities/datapackage/82dd820c-de69-49b7-a792-c418c73153bf
baboons <- read_csv("~/Downloads/Collective movement in wild baboons-gps-1of4.csv")

library(sf)

# First, convert the input dataset to an sf object
baboons_sf <- baboons %>%
  na.omit() %>%
  st_as_sf(coords = c("location-long", "location-lat"), crs = 4326)

# Now, let's ensure the data is sorted by timestamp for each baboon
baboons_sorted <- baboons_sf %>%
  arrange(`tag-local-identifier`, timestamp)

# Create the lines for each baboon
baboon_paths <- baboons_sorted %>%
  group_by(`tag-local-identifier`) %>%
  summarise(do_union = FALSE) %>%
  st_cast("LINESTRING")

first_baboon <- filter(baboon_paths, `tag-local-identifier` == 2426)

baboon_path <- mapboxgl(
  bounds = first_baboon,
  style = mapbox_style("standard-satellite"),
  customAttribution = "<a href='https://datarepository.movebank.org/entities/datapackage/82dd820c-de69-49b7-a792-c418c73153bf'>Crofoot MC, Kays R, Wikelski M. (2021)</a>"
) %>%
  add_source(
    id = "path",
    data = first_baboon,
    lineMetrics = TRUE
  ) %>%
  add_line_layer(
    id = "path-layer",
    source = "path",
    line_width = 3,
    line_gradient = interpolate(
      property = "line-progress",
      values = seq(0, 1, 0.01),
      stops = viridisLite::viridis(101)
    )
  ) %>%
  add_legend(
    legend_title = "Baboon journey, August 1-7 2012",
    values = c("Start", "Finish"),
    colors = viridisLite::viridis(101)
  )

baboon_path

# Save the map
htmlwidgets::saveWidget(baboon_path, "day-5-journey/index.html")