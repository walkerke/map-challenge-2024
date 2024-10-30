library(mapgl)

globe_with_minimap <- mapboxgl() |> 
  add_globe_minimap(
    water_color = "white",
    land_color = "black",
    marker_color = "green"
  )

globe_with_minimap

htmlwidgets::saveWidget(globe_with_minimap, "day-13-a-new-tool/index.html", selfcontained = FALSE)
