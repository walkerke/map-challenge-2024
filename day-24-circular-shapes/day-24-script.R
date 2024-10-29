library(tidycensus)
library(tigris)
library(cartogram)
library(dplyr)
library(mapgl)

us_county_pop <- get_estimates(
  geography = "county",
  vintage = 2023,
  variables = c("POPESTIMATE", "RNETMIG"),
  geometry = TRUE,
  output = "wide"
) %>%
  shift_geometry() %>%
  mutate(pop_proportion = POPESTIMATE / sum(POPESTIMATE, na.rm = TRUE))

dorling <- cartogram_dorling(us_county_pop, "pop_proportion", k = 0.2, itermax = 100)

readr::write_rds(dorling, "day-24-circular-shapes/dorling.rds")

style <- list(
  version = 8,
  sources = structure(list(), .Names = character(0)),
  layers = list(
    list(
      id = "background",
      type = "background",
      paint = list(
        `background-color` = "lightgrey"
      )
    )
  )
)

dorling <- readr::read_rds("day-24-circular-shapes/dorling.rds") %>%
  select(NAME, RNETMIG) %>%
  mutate(NAME = utf8::utf8_encode(NAME)) %>%
  mutate(tooltip = paste0("<b>", NAME, "</b><br>Net migration rate: ", round(RNETMIG, 2)))


state_borders <- states(cb = TRUE, year = 2023, resolution = "20m") %>%
  filter(GEOID != "72") %>%
  shift_geometry()



dorling_map <- mapboxgl(style = style, projection = "albers",
        center = c(-98.8, 37.68),
        zoom = 2.5) |> 
  add_source(
    id = "dorling",
    data = dorling,
    tolerance = 0
  ) |> 
  add_line_layer(
    id = "state_borders",
    source = state_borders,
    line_color = "black",
    line_width = 0.5
  ) |> 
  add_fill_layer(
    id = "dorling",
    source = "dorling",
    fill_color = interpolate(
      column = 'RNETMIG',
      values = c(-50, 0, 67),
      stops = c("#075af4", "#ffffff", "#f30303"),
    ),
    fill_outline_color = "black",
    fill_opacity = 0.8,
    tooltip = "tooltip",
    hover_options = list(
      fill_opacity = 1
    )
  ) |> 
  add_legend(
    "<span style='font-weight: bold;'>Net migration rate, 2023</span><br><span style='font-size: 0.9em;'>Dorling cartogram of US counties; county positions may differ from actual locations</span>",
     values = c("-50", "0", "+67"),
     colors = c("#075af4", "#ffffff", "#f30303")
  )

dorling_map

htmlwidgets::saveWidget(dorling_map, "day-24-circular-shapes/index.html")