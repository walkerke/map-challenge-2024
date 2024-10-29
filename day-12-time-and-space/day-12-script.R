library(tidycensus)
library(sf)
library(tidyverse)
library(mapgl)
options(tigris_use_cache = TRUE)

popdensity_00 <- get_decennial(
  geography = "tract",
  state = "TX",
  county = c("Bastrop", "Caldwell", "Hays",
             "Travis", "Williamson"),
  variables = "P001001",
  sumfile = "sf1",
  year = 2000,
  geometry = TRUE
) %>%
  st_transform(26914) %>%
  mutate(pop_density = as.numeric(value / (st_area(.) / 2589989.1738453)) )

popdensity_22 <- get_acs(
  geography = "tract",
  state = "TX",
  county = c("Bastrop", "Caldwell", "Hays",
             "Travis", "Williamson"),
  variables = "B01001_001",
  year = 2022,
  geometry = TRUE
) %>%
  st_transform(26914) %>%
  mutate(pop_density = as.numeric(estimate / (st_area(.) / 2589989.1738453)) )

map1 <- mapboxgl(bounds = popdensity_00) %>%
  add_fill_extrusion_layer(
    id = "pop2000",
    source = popdensity_00,
    fill_extrusion_color = interpolate(
      "pop_density",
      values = c(0, 18000),
      stops = c("#FFD580", "#FF5733")
    ),
    fill_extrusion_height = get_column("pop_density"),
    fill_extrusion_opacity = 0.7
  ) %>%
  add_continuous_legend(
    "Population density<br>2000 Census / 2018-22 ACS",
    values = c("0", "18k"),
    colors = c("#FFD580", "#FF5733")
  )

map2 <- mapboxgl(bounds = popdensity_22) %>%
  add_fill_extrusion_layer(
    id = "pop2022",
    source = popdensity_22,
    fill_extrusion_color = interpolate(
      "pop_density",
      values = c(0, 18000),
      stops = c("#FFD580", "#FF5733")
    ),
    fill_extrusion_height = get_column("pop_density"),
    fill_extrusion_opacity = 0.7
  )

compare(map1, map2)