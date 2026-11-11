test_that("windsor_police_categories() lists the known categories", {
  cats <- windsor_police_categories()
  expect_equal(length(cats), 17)
  expect_true("Traffic" %in% cats)
  expect_true("Theft" %in% cats)
})

test_that("windsor_police_incidents() reads a sample", {
  skip_if_offline()
  skip_on_cran()
  x <- windsor_police_incidents(n_max = 5)
  expect_s3_class(x, "sf")
  expect_equal(nrow(x), 5)
  expect_true(all(c("category", "location_block", "occ_num", "incident_datetime") %in% names(x)))
  expect_equal(sf::st_crs(x)$epsg, 26917)
})

test_that("windsor_police_incidents() filters by category", {
  skip_if_offline()
  skip_on_cran()
  x <- windsor_police_incidents(category = "Traffic", n_max = 5)
  expect_equal(nrow(x), 5)
  expect_true(all(x$category == "Traffic"))
})

test_that("windsor_police_incidents() filters by local date", {
  skip_if_offline()
  skip_on_cran()
  x <- windsor_police_incidents(start_date = "2026-11-01", end_date = "2026-11-10")
  expect_true(nrow(x) > 0)
  local_date <- as.Date(x$incident_datetime, tz = "America/Toronto")
  expect_true(all(local_date >= as.Date("2026-11-01")))
  expect_true(all(local_date <= as.Date("2026-11-10")))
})

test_that("windsor_police_incidents() rejects an unknown category", {
  expect_error(windsor_police_incidents(category = "Not a category"), "Unknown incident category")
})
