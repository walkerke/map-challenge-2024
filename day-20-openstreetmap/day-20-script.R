library(mapgl)

# Set your MAPTILER_API_KEY as an env variable first
# Then, use the classic OSM tiles in your map!
osm <- maplibre(style = maptiler_style("openstreetmap"), 
         center = c(15.2663, -4.4419),  
         zoom = 10)

osm

htmlwidgets::saveWidget(osm, "day-20-openstreetmap/index.html", selfcontained = FALSE)