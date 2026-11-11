test_that("windsor_datasets returns the snapshot catalogue", {
  skip_if_not_installed("tibble")
  d <- windsor_datasets()
  expect_s3_class(d, "tbl_df")
  expect_true(nrow(d) >= 200)
  expect_true(all(c("dataset", "title", "service", "layer_id", "type", "url") %in% names(d)))
  expect_true("municipal_ward_boundary" %in% d$dataset)
  expect_true("peche_island_pathway" %in% d$dataset)
  expect_true("street_centreline" %in% d$dataset)
})

test_that("windsor_services lists nine services", {
  s <- windsor_services()
  expect_equal(nrow(s), 9)
  expect_true(all(c("boundaries", "transportation") %in% s$service))
  expect_equal(sum(s$n_datasets), nrow(windsor_datasets()))
})

test_that("windsor_search finds datasets by part of a name", {
  expect_true(nrow(windsor_search("ward")) >= 1)
  expect_true(all(grepl("ward", windsor_search("ward")$dataset, ignore.case = TRUE) |
    grepl("ward", windsor_search("ward")$title, ignore.case = TRUE)))
  expect_true(nrow(windsor_search("trail")) >= 1)
  expect_equal(nrow(windsor_search("zzzznotarealdataset")), 0)
})

test_that("windsor_get resolves aliases and titles", {
  skip_if_offline()
  skip_on_cran()
  wards <- windsor_get("ward_boundaries")
  expect_s3_class(wards, "sf")
  expect_equal(nrow(wards), 10)
  expect_true("ward_number" %in% names(wards))
  peche <- windsor_get("Peche Island Pathway")
  expect_s3_class(peche, "sf")
  expect_equal(nrow(peche), 3)
})
