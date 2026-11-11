# windsoropendata NEWS

## windsoropendata 0.3.0 (2026-11-10)

* New `windsor_tomtom_flow()` reads live measured traffic speed from
  the TomTom Traffic API (Flow Segment Data, version 4): current speed
  and free flow speed, travel times, confidence and functional road
  class for the road segment closest to each point. Each point costs
  one TomTom API call.
* New `windsor_tomtom_incidents()` reads live traffic incidents from
  the TomTom Traffic API (Incident Details, version 5) for a bounding
  box, defaulting to Windsor: accidents, jams, road closures, roadworks
  and other incidents, with location, delay and description, as an
  `sf` object in EPSG 4326. One call per bounding box query.
* New `windsor_tomtom_categories()` lists the 13 TomTom incident
  categories, and `windsor_tomtom_bbox()` returns the default Windsor
  bounding box.
* Both TomTom functions need a free TomTom API key, read from the
  `TOMTOM_API_KEY` environment variable. Get a key at
  developer.tomtom.com (no credit card). The key is never stored by
  the package. TomTom is a separate commercial source, not part of the
  City open data portal, and its live data is not stored or
  redistributed by this package.

## windsoropendata 0.2.0 (2026-11-10)

* New `windsor_police_incidents()` reads police-reported incidents from
  the Windsor Police Service Incident Dashboard, a public ArcGIS
  FeatureServer separate from the City open data portal. It covers
  Windsor and Amherstburg for the last two years, with a category
  filter, an inclusive start and end date filter interpreted in
  America/Toronto, and pagination handled by `arcgislayers::arc_read()`.
  The full two years is about 38,000 records and takes about 10 seconds.
* New `windsor_police_categories()` lists the 17 incident categories.

## windsoropendata 0.1.0 (2026-11-10)

* First release: `windsor_datasets()`, `windsor_search()`,
  `windsor_get()`, `windsor_services()` and `windsor_refresh()` for the
  227 datasets in the City of Windsor open data portal, plus a hex
  sticker and a getting started vignette.
