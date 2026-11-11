#' Live traffic speeds and incidents from TomTom
#'
#' Reads live traffic data for Windsor from the TomTom Traffic API.
#' This is a separate, commercial source from the City of Windsor open
#' data portal: TomTom publishes no Windsor speed or incident dataset,
#' so the only way to get measured speeds for Windsor streets is to
#' query TomTom's live probe data, one point or one bounding box at a
#' time.
#'
#' You need a free TomTom API key. Get one at
#' <https://developer.tomtom.com/> (no credit card), then set it in R
#' with `Sys.setenv(TOMTOM_API_KEY = "your-key")`, or add
#' `TOMTOM_API_KEY=your-key` to your `~/.Renviron` file and restart R.
#' The key is read from the `TOMTOM_API_KEY` environment variable, and
#' is never stored by this package. TomTom's free tier is limited, so
#' each point in [windsor_tomtom_flow()] costs one API call, and each
#' call to [windsor_tomtom_incidents()] costs one API call. TomTom's
#' pricing page lists the Traffic free allowances in monthly amounts
#' (2.5K monthly for one Traffic product, 200K monthly for others, as
#' of 2026-11-10); older guides quote 2,500 per day, so check your
#' account dashboard before building a frequent polling loop.
#'
#' @name windsor_tomtom
NULL

#' Default Windsor bounding box for TomTom queries
#'
#' A bounding box around the City of Windsor, in longitude and
#' latitude (EPSG 4326), slightly wider than the 10 ward boundaries so
#' it includes the E.C. Row Expressway and the border crossings.
#' Order is `minLon, minLat, maxLon, maxLat`, the order TomTom wants.
#'
#' @return A named numeric vector of length 4: `xmin`, `ymin`, `xmax`,
#'   `ymax`.
#'
#' @examples
#' windsor_tomtom_bbox()
#'
#' @export
windsor_tomtom_bbox <- function() {
  c(xmin = -83.20, ymin = 42.20, xmax = -82.85, ymax = 42.36)
}

#' TomTom traffic incident categories
#'
#' The incident categories TomTom uses in its Traffic Incidents API,
#' with the numeric code TomTom uses for each one. Pass the names, for
#' example `"Accident"`, to the `category` argument of
#' [windsor_tomtom_incidents()].
#'
#' @return A named integer vector: names are the category names, values
#'   are the TomTom codes.
#'
#' @examples
#' windsor_tomtom_categories()
#'
#' @export
windsor_tomtom_categories <- function() {
  c(
    "Unknown" = 0L,
    "Accident" = 1L,
    "Fog" = 2L,
    "DangerousConditions" = 3L,
    "Rain" = 4L,
    "Ice" = 5L,
    "Jam" = 6L,
    "LaneClosed" = 7L,
    "RoadClosed" = 8L,
    "RoadWorks" = 9L,
    "Wind" = 10L,
    "Flooding" = 11L,
    "BrokenDownVehicle" = 14L
  )
}

#' Live traffic speed at one or more points
#'
#' Queries the TomTom Traffic Flow API (Flow Segment Data, version 4)
#' for the road segment closest to each point. Returns the current
#' average speed, the free flow speed, travel times, and a confidence
#' score for each point. This is measured speed from TomTom probe
#' data, not a posted speed limit.
#'
#' Each point costs one TomTom API call. Keep the number of points
#' small when polling often: 100 points every 15 minutes is about
#' 9,600 calls a day, far above the free tier.
#'
#' @param lat,lon Numeric vectors of latitude and longitude, in
#'   decimal degrees (EPSG 4326). They must be the same length. Or,
#'   pass a single `sf` object with point geometry, or a data frame
#'   with `lat`/`lon` (or `latitude`/`longitude`, or `y`/`x`) columns,
#'   as `lat` and leave `lon` as `NULL`.
#' @param key A TomTom API key. Defaults to the `TOMTOM_API_KEY`
#'   environment variable. See the Details section of
#'   [windsor_tomtom].
#' @param zoom Zoom level, 0 to 22. Higher values show lower importance
#'   roads. Defaults to 10, which covers arterials and collectors.
#'   Use 14 or higher for local streets.
#' @param unit Speed unit, `"kmph"` (default) or `"mph"`.
#'
#' @return An `sf` object with point geometry at the queried points,
#'   in EPSG 4326 (WGS 84). Columns include `lat`, `lon`,
#'   `current_speed`, `free_flow_speed`, `speed_ratio`
#'   (`current_speed / free_flow_speed`), `current_travel_time`,
#'   `free_flow_travel_time`, `delay_seconds`, `confidence` (0 to 1),
#'   `frc` (functional road class, `FRC0` motorway to `FRC6` local
#'   road) and `road_closure`. Speeds are in the requested unit.
#'   `queried_at` is the time of the query, in UTC.
#'
#' @examples
#' \dontrun{
#' # Downtown Windsor, Ouellette Ave at Wyandotte St
#' windsor_tomtom_flow(lat = 42.318, lon = -83.039)
#'
#' # Several points at once
#' windsor_tomtom_flow(
#'   lat = c(42.318, 42.300, 42.280),
#'   lon = c(-83.039, -83.000, -82.970)
#' )
#' }
#'
#' @export
windsor_tomtom_flow <- function(lat, lon = NULL, key = NULL, zoom = 10, unit = c("kmph", "mph")) {
  unit <- match.arg(unit)
  pts <- .tomtom_points(lat, lon)
  if (zoom < 0 || zoom > 22) {
    stop("zoom must be between 0 and 22.", call. = FALSE)
  }
  key <- .tomtom_key(key)
  queried_at <- Sys.time()

  rows <- vector("list", nrow(pts))
  for (i in seq_len(nrow(pts))) {
    # The zoom is in the path, not a query parameter.
    req <- httr2::request(paste0(
      "https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/",
      as.integer(zoom), "/json"
    ))
    resp <- .tomtom_perform(req, key = key, point = paste0(pts$lat[i], ",", pts$lon[i]), unit = unit)
    rows[[i]] <- .parse_tomtom_flow(resp, pts$lat[i], pts$lon[i], queried_at)
  }
  out <- dplyr::bind_rows(rows)
  .tomtom_as_sf(out, lon_col = "lon", lat_col = "lat")
}

#' Live traffic incidents in Windsor
#'
#' Queries the TomTom Traffic Incidents API (Incident Details,
#' version 5) for incidents inside a bounding box. Returns accidents,
#' jams, road closures, roadworks and other incidents, with their
#' location, delay and description. Data is updated every minute.
#' This is not a collision dataset: TomTom incidents are live traffic
#' events reported from probe data and other sources, and an
#' "Accident" here is a traffic incident, not a police collision
#' record.
#'
#' @param bbox Bounding box as a numeric vector of length 4, in the
#'   order `minLon, minLat, maxLon, maxLat` (EPSG 4326). Defaults to
#'   [windsor_tomtom_bbox()], the City of Windsor. The maximum area
#'   is 10,000 square km. An `sf` object or an `sf` bounding box is
#'   also accepted, and is converted to its bounding box.
#' @param key A TomTom API key. Defaults to the `TOMTOM_API_KEY`
#'   environment variable. See the Details section of
#'   [windsor_tomtom].
#' @param category Character vector of incident categories to keep,
#'   for example `"Accident"` or `c("Jam", "RoadClosed")`. Use
#'   [windsor_tomtom_categories()] for the full list. If `NULL`, all
#'   categories are returned.
#' @param time_validity `"present"` (default, active now) or
#'   `"future"` (planned incidents), or both.
#' @param language Language code for incident descriptions, for
#'   example `"en-GB"` (default) or `"en-US"`.
#'
#' @return An `sf` object in EPSG 4326 (WGS 84), with one row per
#'   incident. Geometry is a point for a localised incident and a
#'   line for one spanning a stretch of road. Columns include `id`,
#'   `icon_category`, `icon_category_label`, `magnitude_of_delay`,
#'   `delay_label`, `description`, `event_code`, `from`, `to`,
#'   `length_m`, `delay_s`, `road_numbers`, `start_time`, `end_time`,
#'   `time_validity`, `probability_of_occurrence`,
#'   `number_of_reports` and `last_report_time`. `queried_at` is the
#'   time of the query, in UTC. If there are no incidents, an empty
#'   `sf` object with the same columns is returned.
#'
#' @examples
#' \dontrun{
#' # All current incidents in Windsor
#' windsor_tomtom_incidents()
#'
#' # Accidents only
#' windsor_tomtom_incidents(category = "Accident")
#'
#' # A smaller box, downtown only
#' windsor_tomtom_incidents(bbox = c(-83.06, 42.30, -83.00, 42.33))
#' }
#'
#' @export
windsor_tomtom_incidents <- function(bbox = NULL, key = NULL, category = NULL,
                                     time_validity = c("present", "future"),
                                     language = "en-GB") {
  time_validity <- match.arg(time_validity, several.ok = TRUE)
  box <- .tomtom_bbox(bbox)
  if (!is.null(category)) {
    valid <- windsor_tomtom_categories()
    bad <- setdiff(category, names(valid))
    if (length(bad) > 0) {
      stop(
        "Unknown TomTom incident category: ", paste0("'", bad, "'", collapse = ", "), ". ",
        "Use windsor_tomtom_categories() for the full list.",
        call. = FALSE
      )
    }
  }
  key <- .tomtom_key(key)
  queried_at <- Sys.time()

  fields <- paste0(
    "{incidents{type,geometry{type,coordinates},properties{",
    "id,iconCategory,magnitudeOfDelay,events{description,code,iconCategory},",
    "startTime,endTime,from,to,length,delay,roadNumbers,timeValidity,",
    "probabilityOfOccurrence,numberOfReports,lastReportTime}}}"
  )
  req <- httr2::request("https://api.tomtom.com/traffic/services/5/incidentDetails")
  query <- list(
    key = key,
    bbox = paste(box, collapse = ","),
    fields = fields,
    language = language,
    timeValidityFilter = paste(time_validity, collapse = ",")
  )
  if (!is.null(category)) {
    query$categoryFilter <- paste(category, collapse = ",")
  }
  resp <- .tomtom_perform(req, query = query)
  .parse_tomtom_incidents(resp, queried_at)
}

# Read the TomTom key from the argument or the TOMTOM_API_KEY
# environment variable. Errors with setup instructions when missing.
.tomtom_key <- function(key) {
  if (!is.null(key) && nzchar(key)) {
    return(key)
  }
  env <- Sys.getenv("TOMTOM_API_KEY", unset = "")
  if (nzchar(env)) {
    return(env)
  }
  stop(
    "No TomTom API key found. Get a free key at https://developer.tomtom.com/ ",
    "(no credit card), then set it with ",
    "Sys.setenv(TOMTOM_API_KEY = \"your-key\"), or add ",
    "TOMTOM_API_KEY=your-key to your ~/.Renviron file and restart R.",
    call. = FALSE
  )
}

# Normalise lat/lon input for windsor_tomtom_flow() to a data frame
# with lat and lon columns. Accepts numeric vectors, an sf point
# object, or a data frame with lat/lon columns.
.tomtom_points <- function(lat, lon = NULL) {
  if (inherits(lat, "sf")) {
    if (!requireNamespace("sf", quietly = TRUE)) {
      stop("The sf package is needed to use an sf object here.", call. = FALSE)
    }
    lat <- sf::st_transform(lat, 4326)
    coords <- sf::st_coordinates(lat)
    pts <- data.frame(lat = coords[, "Y"], lon = coords[, "X"])
  } else if (is.data.frame(lat) && is.null(lon)) {
    df <- lat
    lat_col <- intersect(c("lat", "latitude", "y"), names(df))[1]
    lon_col <- intersect(c("lon", "lng", "longitude", "x"), names(df))[1]
    if (is.na(lat_col) || is.na(lon_col)) {
      stop("The data frame must have lat and lon columns (or latitude/longitude).", call. = FALSE)
    }
    pts <- data.frame(lat = as.numeric(df[[lat_col]]), lon = as.numeric(df[[lon_col]]))
  } else {
    if (is.null(lon) || length(lat) != length(lon)) {
      stop("lat and lon must be numeric vectors of the same length.", call. = FALSE)
    }
    pts <- data.frame(lat = as.numeric(lat), lon = as.numeric(lon))
  }
  if (any(!is.finite(pts$lat)) || any(!is.finite(pts$lon))) {
    stop("lat and lon must be finite numbers.", call. = FALSE)
  }
  if (any(pts$lat < -90 | pts$lat > 90) || any(pts$lon < -180 | pts$lon > 180)) {
    stop("lat must be between -90 and 90 and lon between -180 and 180.", call. = FALSE)
  }
  pts
}

# Normalise a bounding box to a numeric vector of length 4, in the
# order minLon, minLat, maxLon, maxLat.
.tomtom_bbox <- function(bbox) {
  if (is.null(bbox)) {
    return(windsor_tomtom_bbox())
  }
  if (inherits(bbox, "sf") || inherits(bbox, "sfc")) {
    if (!requireNamespace("sf", quietly = TRUE)) {
      stop("The sf package is needed to use an sf object here.", call. = FALSE)
    }
    box <- sf::st_bbox(sf::st_transform(bbox, 4326))
    return(c(xmin = unname(box["xmin"]), ymin = unname(box["ymin"]),
             xmax = unname(box["xmax"]), ymax = unname(box["ymax"])))
  }
  if (!is.numeric(bbox) || length(bbox) != 4 || any(!is.finite(bbox))) {
    stop("bbox must be a numeric vector of length 4: c(minLon, minLat, maxLon, maxLat).", call. = FALSE)
  }
  if (bbox[1] >= bbox[3] || bbox[2] >= bbox[4]) {
    stop("bbox must have minLon < maxLon and minLat < maxLat.", call. = FALSE)
  }
  unname(bbox)
}

# Perform a TomTom GET request, with the key added, and turn HTTP
# errors into readable R errors. `...` are extra query parameters,
# `query` is a named list of query parameters (used by incidents).
.tomtom_perform <- function(req, key = NULL, query = NULL, ...) {
  q <- c(list(key = key), query, list(...))
  q <- q[!vapply(q, is.null, logical(1))]
  req <- httr2::req_url_query(req, !!!q)
  req <- httr2::req_error(req, body = function(resp) {
    body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = TRUE), error = function(e) NULL)
    msg <- body$detailedError$message %||% body$message %||% body$error %||% "TomTom request failed."
    paste0("TomTom API error (HTTP ", httr2::resp_status(resp), "): ", msg)
  })
  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http_403 = function(e) {
      stop("TomTom rejected the API key (HTTP 403). Check that the key is correct and that the Traffic API is enabled for it at developer.tomtom.com.", call. = FALSE)
    },
    httr2_http_429 = function(e) {
      stop("TomTom rate limit reached (HTTP 429). Wait before trying again, and check your free tier allowance.", call. = FALSE)
    }
  )
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

# Parse one Flow Segment Data response into a one row tibble.
.parse_tomtom_flow <- function(resp, lat, lon, queried_at) {
  d <- resp$flowSegmentData %||% list()
  current <- .tomtom_num(d$currentSpeed)
  free <- .tomtom_num(d$freeFlowSpeed)
  tibble::tibble(
    lat = lat,
    lon = lon,
    current_speed = current,
    free_flow_speed = free,
    speed_ratio = if (is.na(free) || free == 0) NA_real_ else current / free,
    current_travel_time = .tomtom_num(d$currentTravelTime),
    free_flow_travel_time = .tomtom_num(d$freeFlowTravelTime),
    delay_seconds = .tomtom_num(d$currentTravelTime) - .tomtom_num(d$freeFlowTravelTime),
    confidence = .tomtom_num(d$confidence),
    frc = d$frc %||% NA_character_,
    road_closure = .tomtom_lgl(d$roadClosure),
    queried_at = queried_at
  )
}

# Parse an Incident Details response into an sf object. Geometry is
# a point for a localised incident and a line for one spanning a
# stretch of road.
.parse_tomtom_incidents <- function(resp, queried_at) {
  incidents <- resp$incidents %||% list()
  cols <- c(
    "id", "icon_category", "icon_category_label", "magnitude_of_delay",
    "delay_label", "description", "event_code", "from", "to",
    "length_m", "delay_s", "road_numbers", "start_time", "end_time",
    "time_validity", "probability_of_occurrence", "number_of_reports",
    "last_report_time", "geometry_type", "queried_at"
  )
  if (length(incidents) == 0) {
    empty <- tibble::tibble(
      id = character(), icon_category = integer(), icon_category_label = character(),
      magnitude_of_delay = integer(), delay_label = character(),
      description = character(), event_code = integer(), from = character(),
      to = character(), length_m = numeric(), delay_s = numeric(),
      road_numbers = character(), start_time = as.POSIXct(character()),
      end_time = as.POSIXct(character()), time_validity = character(),
      probability_of_occurrence = character(), number_of_reports = integer(),
      last_report_time = as.POSIXct(character()), geometry_type = character(),
      queried_at = as.POSIXct(character())
    )
    return(sf::st_sf(empty, geometry = sf::st_sfc(crs = 4326)))
  }

  geoms <- vector("list", length(incidents))
  rows <- vector("list", length(incidents))
  for (i in seq_along(incidents)) {
    inc <- incidents[[i]]
    geom <- inc$geometry %||% list()
    coords <- .tomtom_coords(geom$coordinates)
    geoms[[i]] <- if (identical(geom$type, "LineString") && nrow(coords) > 1) {
      sf::st_linestring(coords)
    } else {
      sf::st_point(coords[1, ])
    }
    p <- inc$properties %||% list()
    events <- p$events %||% list()
    first_event <- if (length(events) > 0) events[[1]] else list()
    icon_cat <- .tomtom_int(p$iconCategory)
    delay_mag <- .tomtom_int(p$magnitudeOfDelay)
    rows[[i]] <- tibble::tibble(
      id = p$id %||% NA_character_,
      icon_category = icon_cat,
      icon_category_label = .tomtom_icon_label(icon_cat),
      magnitude_of_delay = delay_mag,
      delay_label = .tomtom_delay_label(delay_mag),
      description = first_event$description %||% NA_character_,
      event_code = .tomtom_int(first_event$code),
      from = p$from %||% NA_character_,
      to = p$to %||% NA_character_,
      length_m = .tomtom_num(p$length),
      delay_s = .tomtom_num(p$delay),
      road_numbers = paste(unlist(p$roadNumbers), collapse = ", "),
      start_time = .tomtom_time(p$startTime),
      end_time = .tomtom_time(p$endTime),
      time_validity = p$timeValidity %||% NA_character_,
      probability_of_occurrence = p$probabilityOfOccurrence %||% NA_character_,
      number_of_reports = .tomtom_int(p$numberOfReports),
      last_report_time = .tomtom_time(p$lastReportTime),
      geometry_type = geom$type %||% NA_character_,
      queried_at = queried_at
    )
  }
  out <- dplyr::bind_rows(rows)
  sf::st_sf(out, geometry = sf::st_sfc(geoms, crs = 4326))
}

# Turn TomTom incident geometry coordinates into a lon/lat matrix.
# Point: [lon, lat]. LineString: [[lon, lat], ...].
.tomtom_coords <- function(coords) {
  if (is.null(coords) || length(coords) == 0) {
    return(matrix(c(NA_real_, NA_real_), nrow = 1))
  }
  # A point comes back as a list of two numbers, c(lon, lat), or as a
  # numeric vector of length 2. A line comes back as a list of points.
  if (is.numeric(coords) && length(coords) == 2) {
    return(matrix(coords, nrow = 1))
  }
  if (is.list(coords) && length(coords) == 2 &&
      length(coords[[1]]) == 1 && length(coords[[2]]) == 1) {
    return(matrix(c(as.numeric(coords[[1]]), as.numeric(coords[[2]])), nrow = 1))
  }
  mat <- do.call(rbind, lapply(coords, function(pt) {
    pt <- unlist(pt)
    c(as.numeric(pt[1]), as.numeric(pt[2]))
  }))
  colnames(mat) <- c("lon", "lat")
  mat
}

.tomtom_icon_label <- function(code) {
  labels <- c(
    "0" = "Unknown", "1" = "Accident", "2" = "Fog",
    "3" = "DangerousConditions", "4" = "Rain", "5" = "Ice",
    "6" = "Jam", "7" = "LaneClosed", "8" = "RoadClosed",
    "9" = "RoadWorks", "10" = "Wind", "11" = "Flooding",
    "14" = "BrokenDownVehicle"
  )
  if (is.na(code)) return(NA_character_)
  lab <- unname(labels[as.character(code)])
  if (is.na(lab)) "Unknown" else lab
}

.tomtom_delay_label <- function(code) {
  labels <- c("0" = "Unknown", "1" = "Minor", "2" = "Moderate", "3" = "Major", "4" = "Undefined")
  if (is.na(code)) return(NA_character_)
  lab <- unname(labels[as.character(code)])
  if (is.na(lab)) "Unknown" else lab
}

.tomtom_num <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_real_)
  suppressWarnings(as.numeric(x))
}

.tomtom_int <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_integer_)
  suppressWarnings(as.integer(x))
}

.tomtom_lgl <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  as.logical(x)
}

.tomtom_time <- function(x) {
  if (is.null(x) || length(x) == 0 || !nzchar(x)) {
    return(as.POSIXct(NA, tz = "UTC"))
  }
  parsed <- suppressWarnings(as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"))
  if (is.na(parsed)) {
    parsed <- suppressWarnings(as.POSIXct(x, tz = "UTC"))
  }
  parsed
}

# Convert a tibble with lon/lat columns to an sf point object.
.tomtom_as_sf <- function(df, lon_col = "lon", lat_col = "lat") {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("The sf package is needed for TomTom results. Install it with install.packages(\"sf\").", call. = FALSE)
  }
  sf::st_as_sf(df, coords = c(lon_col, lat_col), crs = 4326, remove = FALSE)
}
