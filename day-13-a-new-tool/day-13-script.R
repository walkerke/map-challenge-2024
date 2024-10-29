library(mapgl)

mapboxgl() |> 
  add_globe_minimap(
    water_color = "white",
    land_color = "black",
    marker_color = "green"
  )