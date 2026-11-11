# windsoropendata

<!-- badges: start -->
<!-- badges: end -->

<img src="man/figures/logo.png" align="right" height="200" alt="windsoropendata hex sticker: Windsor ward map in a dark blue hexagon" />

Get data from [City of Windsor Open Data Portal](https://open-data-portal-citywindsor.hub.arcgis.com/) in R.

The City of Windsor open data portal is an ArcGIS Hub site, backed by the
City's own ArcGIS Server at `mappmycity.ca`. This package is a thin
wrapper around `arcgislayers::arc_read()`. It knows the Windsor catalogue,
so you list datasets, search them by name, and read one by its short name.

## Installation

```r
install.packages("arcgis")
# install.packages("pak")
pak::pak("durraniu/windsoropendata")
```

## Example

```r
library(windsoropendata)

# What is available? 227 datasets across 9 services, snapshot 2026-11-10
windsor_datasets()

# Find a dataset
windsor_search("ward")
windsor_search("trail")

# Read it by short name, no URL needed
wards <- windsor_get("ward_boundaries")
peche <- windsor_get("peche_island_pathway")
streets <- windsor_get("street_centreline", n_max = 5)
```

Spatial data comes back as an `sf` object in EPSG 26917 (NAD 1983 UTM
Zone 17N), the City's native projection.

Police incidents are obtained from the Windsor Police Service
Incident Dashboard, not the City portal. Read them with a category and
date filter:

```r
incidents <- windsor_police_incidents(n_max = 5)
traffic <- windsor_police_incidents(category = "Traffic", n_max = 5)
recent <- windsor_police_incidents(start_date = "2026-11-01", end_date = "2026-11-10")
windsor_police_categories()
```

See the getting started vignette for the full walkthrough:
`vignette("getting-started", package = "windsoropendata")`.

## Live traffic speeds and incidents, from TomTom

Live speeds and incidents come from the TomTom Traffic API. Get a
free key at https://developer.tomtom.com/ (no credit card), then set
it once per session, or in `~/.Renviron`:

```r
Sys.setenv(TOMTOM_API_KEY = "your-key")

# Current speed and free flow speed at a point, in km/h
windsor_tomtom_flow(lat = 42.318, lon = -83.039)

# All current traffic incidents in Windsor
windsor_tomtom_incidents()

# Accidents only, and the categories TomTom uses
windsor_tomtom_incidents(category = "Accident")
windsor_tomtom_categories()
windsor_tomtom_bbox()
```

Each point in `windsor_tomtom_flow()` costs one TomTom API call, and
each `windsor_tomtom_incidents()` call costs one call. Results are `sf` objects in EPSG 4326.
TomTom incidents are live traffic events, not police collision records.

## Data sources

* Portal: https://open-data-portal-citywindsor.hub.arcgis.com/
* REST services: https://mappmycity.ca/arcgis/rest/services/open_data_services
* Licence: datasets are listed under Creative Commons Attribution 4.0
  International (CC BY 4.0).
* TomTom Traffic API: https://developer.tomtom.com/traffic-api/documentation
  (live speeds and incidents; free key needed, see above).
