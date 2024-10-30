library(mapgl)

globe_with_minimap <- mapboxgl(height = "105vh") |> 
  add_globe_minimap(
    water_color = "white",
    land_color = "black",
    marker_color = "green"
  )

globe_with_minimap
