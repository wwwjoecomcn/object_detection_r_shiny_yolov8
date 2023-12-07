library(googleway)
library(sf)
library(mapsapi)
library(leaflet)

# Load Google api key
source("~/private/googlemap_api_key.R")
googleway::set_key(google_map_api_key)

df <- google_directions(origin = c(44.65412963906289, -63.533649515276515),
                        destination = c(44.6818500894883, -63.52140907283672),
                        mode = "driving",
                        simplify = TRUE)

# Get direction polyline
polyline <- direction_polyline(df)

# Decode as points
df_points <- decode_pl(polyline)
head(df_points)

# Cast points to linestring
point_sf <- st_as_sf(df_points, coords = c("lon", "lat"), crs = 4326)

# Convert points to a linestring
polyline_sf <- st_combine(point_sf) %>% st_cast("LINESTRING")

# 
leaflet() %>% 
  addProviderTiles("OpenTopoMap") %>%
  addCircles(data = point_sf, color = "red") %>%
  leaflet::addPolylines(data = st_transform(polyline_sf, 4326), color = "red")
