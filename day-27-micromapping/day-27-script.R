library(sf)
library(dplyr)
library(mapgl)

# Function to create a floor polygon
create_floor <- function(x, y, width, height, floor_number) {
  polygon <- st_polygon(list(rbind(
    c(x, y),
    c(x + width, y),
    c(x + width, y + height),
    c(x, y + height),
    c(x, y)
  )))
  
  st_sf(floor = floor_number, geometry = st_sfc(polygon, crs = 4326))
}

# Function to create wall polygons - fixed geometry handling
create_walls <- function(geometry, floor_number, wall_thickness = 0.00001) {
  # Ensure we have an sf object
  if (!inherits(geometry, "sf") && !inherits(geometry, "sfc")) {
    geometry <- st_sfc(geometry, crs = 4326)
  }
  
  # Get coordinates
  coords <- st_coordinates(geometry)
  
  # Get unique boundary segments for the first ring (exterior)
  coords <- coords[coords[,"L1"] == 1, c("X", "Y")]
  
  walls <- list()
  n_points <- nrow(coords)
  
  for (i in 1:n_points) {
    if (i == n_points && all(coords[i,] == coords[1,])) next  # Skip last point if it's same as first
    
    start <- coords[i,]
    end <- if (i == n_points) coords[1,] else coords[i + 1,]
    
    direction <- end - start
    if (all(direction == 0)) next  # Skip zero-length segments
    
    perpendicular <- c(-direction[2], direction[1])
    perpendicular <- perpendicular / sqrt(sum(perpendicular^2)) * wall_thickness
    
    wall_coords <- rbind(
      start,
      end,
      end + perpendicular,
      start + perpendicular,
      start
    )
    
    # Create wall polygon
    try({
      wall <- st_polygon(list(wall_coords))
      walls[[length(walls) + 1]] <- st_sf(
        geometry = st_sfc(wall, crs = 4326),
        floor = floor_number,
        name = "Wall",
        height = floor_number * 10
      )
    }, silent = TRUE)
  }
  
  if (length(walls) == 0) return(NULL)
  do.call(rbind, walls)
}

# Coordinates for Prosper, Texas
base_x <- -96.80564 
base_y <- 33.22257  
base_width <- 0.0015  
base_height <- 0.0012  

# Create floors with variations
floors <- list()

# Ground Floor (largest, with atrium)
ground_floor <- create_floor(base_x, base_y, base_width, base_height, 1)
atrium <- create_floor(base_x + 0.0005, base_y + 0.0004, 0.0005, 0.0004, 1)
floors[[1]] <- st_difference(ground_floor, atrium)

# Second Floor (U-shaped)
floor_2 <- create_floor(base_x, base_y, base_width, base_height, 2)
cutout_2 <- create_floor(base_x + 0.0005, base_y + 0.0004, 0.0005, 0.0008, 2)
floors[[2]] <- st_difference(floor_2, cutout_2)

# Third Floor (with two sections removed)
floor_3 <- create_floor(base_x, base_y, base_width, base_height, 3)
cutout_3a <- create_floor(base_x + 0.0002, base_y + 0.0002, 0.0004, 0.0004, 3)
cutout_3b <- create_floor(base_x + base_width - 0.0006, base_y + base_height - 0.0006, 0.0004, 0.0004, 3)
floor_3 <- st_cast(floor_3, "POLYGON")
cutout_3a <- st_cast(cutout_3a, "POLYGON")
cutout_3b <- st_cast(cutout_3b, "POLYGON")
floors[[3]] <- st_difference(floor_3, st_union(cutout_3a, cutout_3b))

# Fourth Floor (H-shaped)
floor_4a <- create_floor(base_x, base_y, 0.0004, base_height, 4)
floor_4b <- create_floor(base_x + base_width - 0.0004, base_y, 0.0004, base_height, 4)
floor_4c <- create_floor(base_x + 0.0004, base_y + 0.0004, 0.0007, 0.0004, 4)
combined_geom <- st_union(st_union(floor_4a$geometry, floor_4b$geometry), floor_4c$geometry)
floors[[4]] <- st_sf(floor = 4, geometry = combined_geom, crs = 4326)

# Fifth Floor (two separate sections)
floor_5a <- create_floor(base_x, base_y, 0.0006, 0.0006, 5)
floor_5b <- create_floor(base_x + base_width - 0.0006, base_y + base_height - 0.0006, 0.0006, 0.0006, 5)
floors[[5]] <- st_sfc(st_multipolygon(list(st_geometry(floor_5a)[[1]], st_geometry(floor_5b)[[1]])))
floors[[5]] <- st_sf(floor = 5, geometry = floors[[5]], crs = 4326)

# Sixth Floor (small penthouse)
floors[[6]] <- create_floor(base_x + 0.00045, base_y + 0.00035, 0.0006, 0.0005, 6)

# Combine all floors into one sf object
building <- bind_rows(floors) 

# Add attributes
building <- building %>%
  mutate(
    floor_name = case_when(
      floor == 1 ~ "Ground Floor & Atrium",
      floor == 2 ~ "Office Space",
      floor == 3 ~ "Conference Level",
      floor == 4 ~ "Executive Suites",
      floor == 5 ~ "Sky Gardens",
      floor == 6 ~ "Penthouse"
    ),
    height = floor * 10
  ) %>%
  arrange(desc(height))

# Create walls for each floor
walls <- list()
for (i in 1:nrow(building)) {
  floor_geom <- building$geometry[[i]]
  floor_num <- building$floor[[i]]
  
  # Handle MULTIPOLYGON case
  if (st_geometry_type(floor_geom) == "MULTIPOLYGON") {
    # Convert MULTIPOLYGON to list of POLYGONs
    polys <- st_collection_extract(floor_geom, "POLYGON")
    for (j in 1:length(polys)) {
      wall_set <- create_walls(polys[j], floor_num)
      if (!is.null(wall_set)) {
        walls[[length(walls) + 1]] <- wall_set
      }
    }
  } else {
    wall_set <- create_walls(floor_geom, floor_num)
    if (!is.null(wall_set)) {
      walls[[length(walls) + 1]] <- wall_set
    }
  }
}

# Combine all walls
all_walls <- bind_rows(walls)

# Create surrounding features
parking_lot <- create_floor(base_x - 0.0005, base_y - 0.0005, 0.0007, 0.0022, 0) %>%
  mutate(feature = "Parking Lot", height = 0)

green_space <- create_floor(base_x + base_width + 0.0002, base_y, 0.0008, 0.0012, 0) %>%
  mutate(feature = "Green Space", height = 0)

# Combine building and surrounding features
all_features <- bind_rows(
  building %>% mutate(feature = "Building"),
  parking_lot,
  green_space
)

# Create the map
floorplan <- mapboxgl(
  style = mapbox_style("light"), 
  center = c(base_x, base_y),
  pitch = 60, 
  bearing = 45, 
  zoom = 16
) %>%
  add_fill_layer(
    id = "Surroundings",
    source = all_features %>% filter(feature != "Building"),
    fill_color = match_expr(
      column = "feature",
      values = c("Parking Lot", "Green Space"),
      stops = c("#666666", "#228B22")
    ),
    fill_opacity = 0.8
  ) %>%
  add_fill_layer(
    id = "Floors",
    source = all_features %>% filter(feature == "Building"),
    fill_color = interpolate(
      column = "floor",
      values = c(1, 6),
      stops = c("#fde0dd", "#c51b8a")
    ),
    fill_opacity = 0.8,
    fill_z_offset = get_column("height")
  ) %>%
  add_fill_extrusion_layer(
    id = "Walls",
    source = all_walls,
    fill_extrusion_color = "#808080",
    fill_extrusion_height = get_column("height"),
    fill_extrusion_opacity = 0.6
  ) %>%
  add_layers_control()

floorplan

htmlwidgets::saveWidget(floorplan, "day-27-micromapping/index.html", selfcontained = FALSE)
