library(mapgl)
library(terra)
library(magrittr)
library(sf)

raster_filepath <- system.file("raster/srtm.tif", package = "spDataLarge")
my_rast <- rast(raster_filepath)
class(my_rast)

raster_map <- maplibre(style = carto_style("positron"), 
         bounds = unname(st_bbox(my_rast))) %>%
  add_image_source(
    id = "raster",
    data = my_rast
  ) %>%
  add_raster_layer(
    id = "raster-layer",
    source = "raster",
    raster_opacity = 0.7
  ) %>%
  add_continuous_legend(
    legend_title = "Elevation in Zion National Park",
    values = c("1024m", "2892m"),
    colors = viridisLite::viridis(100)
  )

raster_map

htmlwidgets::saveWidget(raster_map, "day-6-raster/index.html")
