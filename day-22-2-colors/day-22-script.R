library(mapgl)
library(tigris)
library(tidyverse)
library(sf)

us_places <- places(cb = TRUE, year = 2023)

red <- filter(us_places, str_detect(NAME, regex("pen", ignore_case = TRUE))) |> 
  st_centroid()
