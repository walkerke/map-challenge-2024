library(mapgl)

m1 <- mapboxgl(projection = "equalEarth")

m2 <- mapboxgl(projection = "mercator")

proj_compare <- compare(m1, m2)

proj_compare

htmlwidgets::saveWidget(proj_compare, "day-26-projections/index.html", selfcontained = FALSE)