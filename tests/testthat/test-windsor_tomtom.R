test_that("windsor_tomtom_categories() lists the known categories", {
  cats <- windsor_tomtom_categories()
  expect_equal(length(cats), 13)
  expect_equal(unname(cats["Accident"]), 1L)
  expect_equal(unname(cats["Jam"]), 6L)
  expect_equal(unname(cats["RoadClosed"]), 8L)
})

test_that("windsor_tomtom_bbox() is Windsor, in TomTom order", {
  box <- windsor_tomtom_bbox()
  expect_equal(length(box), 4)
  expect_true(box["xmin"] < -83 && box["xmax"] > -83)
  expect_true(box["ymin"] > 42 && box["ymax"] < 42.4)
  expect_true(box["xmin"] < box["xmax"])
  expect_true(box["ymin"] < box["ymax"])
})

test_that("TomTom functions error clearly without a key", {
  old <- Sys.getenv("TOMTOM_API_KEY", unset = NA)
  Sys.unsetenv("TOMTOM_API_KEY")
  on.exit(if (!is.na(old)) Sys.setenv(TOMTOM_API_KEY = old), add = TRUE)
  expect_error(windsor_tomtom_flow(lat = 42.318, lon = -83.039), "No TomTom API key")
  expect_error(windsor_tomtom_incidents(), "No TomTom API key")
})

test_that("windsor_tomtom_incidents() rejects an unknown category", {
  expect_error(
    windsor_tomtom_incidents(category = "Not a category", key = "dummy"),
    "Unknown TomTom incident category"
  )
})

test_that("flow parser reads a sample TomTom response", {
  resp <- list(flowSegmentData = list(
    frc = "FRC2",
    currentSpeed = 41,
    freeFlowSpeed = 70,
    currentTravelTime = 153,
    freeFlowTravelTime = 90,
    confidence = 0.59,
    roadClosure = TRUE,
    coordinates = list(coordinate = list(
      list(latitude = 52.40476, longitude = 4.844318),
      list(latitude = 52.411312, longitude = 4.8299975)
    ))
  ))
  out <- windsoropendata:::.parse_tomtom_flow(resp, lat = 42.318, lon = -83.039, queried_at = as.POSIXct("2026-11-10 12:00:00", tz = "UTC"))
  expect_equal(out$current_speed, 41)
  expect_equal(out$free_flow_speed, 70)
  expect_equal(out$speed_ratio, 41 / 70)
  expect_equal(out$delay_seconds, 63)
  expect_equal(out$confidence, 0.59)
  expect_equal(out$frc, "FRC2")
  expect_true(out$road_closure)
})

test_that("incidents parser reads point and line incidents", {
  resp <- list(incidents = list(
    list(
      type = "Feature",
      geometry = list(type = "Point", coordinates = list(-83.039, 42.318)),
      properties = list(
        id = "abc123", iconCategory = 1L, magnitudeOfDelay = 2L,
        events = list(list(description = "Accident on Ouellette Ave", code = 101L, iconCategory = 1L)),
        startTime = "2026-11-10T10:00:00", endTime = "2026-11-10T12:00:00",
        from = "Wyandotte St E", to = "Erie St E", length = 500, delay = 300,
        roadNumbers = list("Ouellette Ave"), timeValidity = "present",
        probabilityOfOccurrence = "definite", numberOfReports = 3L,
        lastReportTime = "2026-11-10T10:05:00"
      )
    ),
    list(
      type = "Feature",
      geometry = list(type = "LineString", coordinates = list(list(-83.05, 42.31), list(-83.04, 42.32))),
      properties = list(
        id = "def456", iconCategory = 6L, magnitudeOfDelay = 3L,
        events = list(list(description = "Slow traffic", code = 601L, iconCategory = 6L)),
        startTime = "2026-11-10T09:00:00", endTime = NULL,
        from = "A", to = "B", length = 1200, delay = 600,
        roadNumbers = list(), timeValidity = "present",
        probabilityOfOccurrence = "probable", numberOfReports = 1L,
        lastReportTime = "2026-11-10T09:30:00"
      )
    )
  ))
  out <- windsoropendata:::.parse_tomtom_incidents(resp, queried_at = as.POSIXct("2026-11-10 12:00:00", tz = "UTC"))
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 2)
  expect_equal(out$id, c("abc123", "def456"))
  expect_equal(out$icon_category_label, c("Accident", "Jam"))
  expect_equal(out$delay_label, c("Moderate", "Major"))
  expect_equal(out$description[1], "Accident on Ouellette Ave")
  expect_equal(out$delay_s, c(300, 600))
  expect_equal(as.character(sf::st_geometry_type(out)), c("POINT", "LINESTRING"))
  expect_equal(sf::st_crs(out)$epsg, 4326)
})

test_that("incidents parser returns an empty sf object when there are no incidents", {
  out <- windsoropendata:::.parse_tomtom_incidents(
    list(incidents = list()),
    queried_at = as.POSIXct("2026-11-10 12:00:00", tz = "UTC")
  )
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 0)
  expect_true("icon_category_label" %in% names(out))
})

test_that("windsor_tomtom_flow() reads a live point", {
  skip_if_offline()
  skip_on_cran()
  skip_if(Sys.getenv("TOMTOM_API_KEY") == "", "No TomTom API key set")
  x <- windsor_tomtom_flow(lat = 42.318, lon = -83.039)
  expect_s3_class(x, "sf")
  expect_equal(nrow(x), 1)
  expect_true(all(c("current_speed", "free_flow_speed", "confidence") %in% names(x)))
  expect_true(is.finite(x$current_speed))
  expect_equal(sf::st_crs(x)$epsg, 4326)
})

test_that("windsor_tomtom_incidents() reads live Windsor incidents", {
  skip_if_offline()
  skip_on_cran()
  skip_if(Sys.getenv("TOMTOM_API_KEY") == "", "No TomTom API key set")
  x <- windsor_tomtom_incidents()
  expect_s3_class(x, "sf")
  expect_true(all(c("id", "icon_category_label", "description") %in% names(x)))
  expect_equal(sf::st_crs(x)$epsg, 4326)
})
