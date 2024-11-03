library(sf)
library(dplyr)
library(mapgl)

# Define the base coordinates for our floor (Prosper, Texas)
base_x <- -96.80564
base_y <- 33.22257
floor_width <- 0.0006
floor_height <- 0.0005

# Function to create a room polygon
create_room <- function(x, y, width, height, name, color) {
  polygon <- st_polygon(list(rbind(
    c(x, y),
    c(x + width, y),
    c(x + width, y + height),
    c(x, y + height),
    c(x, y)
  )))
  
  st_sf(
    name = name,
    color = color,
    geometry = st_sfc(polygon, crs = 4326)
  )
}

# Create rooms
rooms <- list(
  create_room(base_x, base_y, 0.0002, 0.0002, "Reception", "#FFA07A"),
  create_room(base_x + 0.0002, base_y, 0.0002, 0.0002, "Conference Room", "#98FB98"),
  create_room(base_x + 0.0004, base_y, 0.0002, 0.0002, "Executive Office", "#DDA0DD"),
  create_room(base_x, base_y + 0.0002, 0.0001, 0.0003, "Open Office Area 1", "#87CEFA"),
  create_room(base_x + 0.0001, base_y + 0.0002, 0.0001, 0.0003, "Open Office Area 2", "#87CEFA"),
  create_room(base_x + 0.0002, base_y + 0.0002, 0.0002, 0.0001, "Break Room", "#F0E68C"),
  create_room(base_x + 0.0004, base_y + 0.0002, 0.0002, 0.0001, "IT Room", "#20B2AA"),
  create_room(base_x + 0.0002, base_y + 0.0003, 0.0002, 0.0002, "Storage", "#D3D3D3"),
  create_room(base_x + 0.0004, base_y + 0.0003, 0.0002, 0.0002, "Meeting Room", "#FFB6C1")
)

# Combine all rooms into one sf object
floor_plan <- do.call(rbind, rooms)

# Function to create wall polygons
create_walls <- function(room, wall_thickness = 0.00001) {
  coords <- st_coordinates(room)[, 1:2]
  walls <- list()
  for (i in 1:(nrow(coords) - 1)) {
    start <- coords[i, ]
    end <- coords[i + 1, ]
    direction <- end - start
    perpendicular <- c(-direction[2], direction[1])
    perpendicular <- perpendicular / sqrt(sum(perpendicular^2)) * wall_thickness
    
    wall <- st_polygon(list(rbind(
      start,
      end,
      end + perpendicular,
      start + perpendicular,
      start
    )))
    
    walls[[i]] <- st_sf(
      geometry = st_sfc(wall, crs = 4326),
      name = "Wall",
      height = 10  # Make walls taller
    )
  }
  do.call(rbind, walls)
}

# Create walls for all rooms
walls <- do.call(rbind, lapply(st_geometry(floor_plan), create_walls))

# Create the map
office_map <- mapboxgl(
  style = mapbox_style("light"),
  center = c(base_x + floor_width / 2, base_y + floor_height / 2),
  zoom = 19,
  pitch = 60,
  bearing = 20
) %>%
  add_fill_layer(
    id = "2d-rooms",
    source = floor_plan,
    fill_color = get_column("color"),
    fill_opacity = 0.7,
    tooltip = "name"
  ) %>%
  add_fill_extrusion_layer(
    id = "3d-walls",
    source = walls,
    fill_extrusion_color = "#808080",
    fill_extrusion_height = get_column("height"),
    fill_extrusion_opacity = 0.6
  )

office_map

htmlwidgets::saveWidget(office_map, "day-27-micromapping/index.html", selfcontained = FALSE)
