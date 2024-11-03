library(mapgl)
library(tigris)
library(tidyverse)
library(sf)

us_places <- places(cb = TRUE, year = 2023)

red <- filter(us_places, str_detect(NAME, regex("red|rouge|rojo|roja", ignore_case = TRUE))) |> 
  st_centroid() |> 
  transmute(name = paste(NAME, STATE_NAME, sep = ", ")) |> 
  mutate(color = "red")

blue <- filter(us_places, str_detect(NAME, regex("blue|bleu|azul", ignore_case = TRUE))) |> 
  st_centroid() |> 
  transmute(name = paste(NAME, STATE_NAME, sep = ", ")) |> 
  mutate(color = "blue")

red_blue <- bind_rows(red, blue)

red_blue_map <- mapboxgl(bounds = red_blue, 
        style = carto_style("positron-no-labels"), 
        projection = "albers") |> 
  add_circle_layer(
    id = "redblue",
    source = red_blue,
    circle_color = match_expr(
      "color",
      values = c("red", "blue"),
      stops = c("red", "blue")
    ), 
    circle_radius = interpolate(
      property = "zoom",
      values = c(2, 14),
      stops = c(2, 14)
    ), 
    tooltip = "name"
  ) |> 
  add_categorical_legend(
    'US places with <span style="color: red; font-weight: bold;">red</span> or<br><span style="color: blue; font-weight: bold;">blue</span> in their names',
    values = c("Red places", "Blue places"),
    colors = c("red", "blue"),
    circular_patches = TRUE
  )

red_blue_map

htmlwidgets::saveWidget(red_blue_map, "day-22-2-colors/index.html", selfcontained = FALSE)
