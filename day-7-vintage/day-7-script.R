library(mapgl)

# Get a georeferenced topo map (in GeoTIFF format)
# from https://ngmdb.usgs.gov/topoview/viewer/#4/39.98/-100.06

# Then, upload as a tileset to your Mapbox Studio account

# Once it has processed, grab the tileset URL and replace
# my URL with your own.  Change the center / zoom accordingly.

historic <- mapboxgl(style = mapbox_style("outdoors"), 
         center = c(-97.3330, 32.7559),
         zoom = 9, 
         customAttribution = "<a href='https://ngmdb.usgs.gov/topoview/viewer/#4/39.98/-100.06'>Source: USGS</a>") %>%
  add_raster_source(
    id = "fw_1894",
    url = "mapbox://kwalkertcu.6mma8wyk"
  ) %>%
  add_raster_layer(
    id = "raster-layer",
    source = "fw_1894",
    raster_opacity = 0.75
  )

historic

htmlwidgets::saveWidget(historic, "day-7-vintage/index.html", selfcontained = FALSE)