library(mapgl)
library(sf)

# Load in Gulf of Mexico pipeline data
# acquired from https://www.data.boem.gov/Main/Mapping.aspx
pipelines <- st_read("day-28-blue-planet/ppl_arcs/ppl_arcs.shp") 

# Add the "blueprint" style to your account
maplibre(
  style = maptiler_style("ocean")
)