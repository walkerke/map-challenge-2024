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

# Coordinates for Prosper, Texas
base_x <- -96.80564 
base_y <- 33.22257  
base_width <- 0.0015  
base_height <- 0.0012  

# Create floors with more complex variations
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

# Combine the geometries
combined_geom <- st_union(st_union(floor_4a$geometry, floor_4b$geometry), floor_4c$geometry)

# Create a new sf object with the combined geometry
floors[[4]] <- st_sf(floor = 4, geometry = combined_geom, crs = 4326)

# Fifth Floor (two separate sections)
floor_5a <- create_floor(base_x, base_y, 0.0006, 0.0006, 5)
floor_5b <- create_floor(base_x + base_width - 0.0006, base_y + base_height - 0.0006, 0.0006, 0.0006, 5)
# Combine the two sections into a single multipolygon
floors[[5]] <- st_sfc(st_multipolygon(list(st_geometry(floor_5a)[[1]], st_geometry(floor_5b)[[1]])))

# Set the CRS and add attributes
floors[[5]] <- st_sf(floor = 5, geometry = floors[[5]], crs = 4326)
# Sixth Floor (small penthouse)
floors[[6]] <- create_floor(base_x + 0.00045, base_y + 0.00035, 0.0006, 0.0005, 6)


# Combine all floors into one sf object
building <- bind_rows(floors)

# Add some attributes
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
  )

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

# Sort by height in descending order
prosper_complex <- all_features %>%
  arrange(desc(height))

# Create the map
floorplan <- mapboxgl(style = mapbox_style("light"), 
         center = c(base_x, base_y),
         pitch = 60, bearing = 45, zoom = 16) %>%
  add_fill_layer(
    id = "prosper-complex-surroundings",
    source = prosper_complex %>% filter(feature != "Building"),
    fill_color = match_expr(
      column = "feature",
      values = c("Parking Lot", "Green Space"),
      stops = c("#666666", "#228B22")
    ),
    fill_opacity = 0.8,
  ) %>%
  add_fill_layer(
    id = "prosper-complex-building-3d",
    source = prosper_complex %>% filter(feature == "Building"),
    fill_color = interpolate(
        column = "floor",
        values = c(1, 6),
        stops = c("#fde0dd", "#c51b8a")
      ),
    fill_opacity = 0.8,
    fill_z_offset = get_column("height")
  ) 

floorplan

htmlwidgets::saveWidget(floorplan, "day-3-polygons/index.html")