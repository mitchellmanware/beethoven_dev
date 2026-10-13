################################################################################
# Process Uber H3 hexagon grid locations as an {sf} object.

################################################################################
# Load libraries and source local functions.
library(amadeus)
library(h3jsr)
source("R/amadeus.R")
source("R/beethoven.R")

################################################################################
sf_states <- tigris::states(cb = TRUE, year = "2024")
sf_conus <- sf_states[
  sf_states$NAME %in% setdiff(state.name, c("Alaska", "Hawaii")),
  "NAME"
]
sf_ct <- sf_states[sf_states$NAME == "Connecticut", ]
sf_proj <- sf::st_transform(sf_ct, "EPSG:4326")

################################################################################
sf_area <- sf::st_sf(
  geometry = sf::st_union(
    sf::st_geometry(
      sf::st_make_valid(sf_proj)
    )
  )
)

################################################################################
chr_hexids <- unique(
  unlist(
    h3jsr::polygon_to_cells(sf_area, res = 6),
    use.names = FALSE
  )
)
chr_hexids <- chr_hexids[!is.na(chr_hexids)]

################################################################################
sf_grid <- sf::st_sf(
  site_id = chr_hexids,
  geometry = h3jsr::cell_to_polygon(chr_hexids)
)
