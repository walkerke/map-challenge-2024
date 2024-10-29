library(mapgl)

m1 <- mapboxgl(projection = "equalEarth")

m2 <- mapboxgl(projection = "mercator")

compare(m1, m2)