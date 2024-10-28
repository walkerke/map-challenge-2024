library(mapgl)
library(sf)
library(dplyr)
library(maps)

# Load world map data
data(world.cities, package = "maps")

# Convert to sf object
world_cities_sf <- st_as_sf(world.cities, coords = c("long", "lat"), crs = 4326)

# Prepare the data
world_cities_sf <- world_cities_sf %>%
  mutate(
    population_category = cut(pop, 
                              breaks = c(0, 100000, 500000, 1000000, 5000000, Inf),
                              labels = c("< 100k", "100k-500k", "500k-1M", "1M-5M", "> 5M"),
                              include.lowest = TRUE),
    tooltip = sprintf(
      "<strong>%s, %s</strong><br>Population: %s",
      name, country.etc, format(pop, big.mark = ",")
    )
  )

# Create color palette
color_palette <- c("#fee5d9", "#fcae91", "#fb6a4a", "#de2d26", "#a50f15")

# Create the map
m <- mapboxgl(style = mapbox_style("light")) %>%
  fit_bounds(world_cities_sf) %>%
  add_circle_layer(
    id = "world-cities",
    source = world_cities_sf,
    circle_color = match_expr(
      column = "population_category",
      values = levels(world_cities_sf$population_category),
      stops = color_palette
    ),
    circle_radius = interpolate(
      column = "pop",
      values = c(0, max(world_cities_sf$pop)),
      stops = c(3, 15)
    ),
    circle_opacity = 0.7,
    tooltip = "tooltip"
  ) %>%
  add_categorical_legend(
    legend_title = "City Population",
    values = levels(world_cities_sf$population_category),
    colors = color_palette,
    circular_patches = TRUE,
    sizes = c(6, 8, 10, 12, 14),  # Increasing sizes for the legend circles
    position = "bottom-left"
  )

# Display the map
m