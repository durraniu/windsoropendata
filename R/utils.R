`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Turn "municipal_ward_boundary" into "Municipal Ward Boundary".
# Keep "Peche" with its accent, and keep "Centreline" as the City spells it.
pretty_title <- function(x) {
  x <- gsub("_", " ", x)
  x <- tools::toTitleCase(tolower(x))
  x <- gsub("Peche", "Peche", x)
  x <- gsub("Essex", "Essex", x)
  x
}

# Normalise a user supplied name so "Ward Boundaries", "ward-boundaries"
# and "ward_boundaries" all match the same dataset.
normalise_name <- function(x) {
  x <- trimws(tolower(x))
  x <- gsub("[ -]+", "_", x)
  x <- gsub("_+", "_", x)
  x
}

# Short aliases for the datasets people ask for most often.
# Each alias maps to the exact layer name in the catalogue.
windsor_aliases <- function() {
  tibble::tibble(
    alias = c(
      "ward_boundaries", "wards", "ward_boundary",
      "city_boundary", "municipal_boundary",
      "street_centreline", "streets", "street_centerline",
      "peche_island", "peche_island_pathway",
      "bus_stop", "bus_stops", "bus_route", "bus_routes",
      "bike_parking", "sidewalk", "sidewalks"
    ),
    dataset = c(
      "municipal_ward_boundary", "municipal_ward_boundary", "municipal_ward_boundary",
      "city_boundary", "city_boundary",
      "street_centreline", "street_centreline", "street_centreline",
      "peche_island_pathway", "peche_island_pathway",
      "bus_stop", "bus_stop", "bus_route", "bus_route",
      "bike_parking", "sidewalk", "sidewalk"
    )
  )
}

# Resolve a user supplied dataset name, title, alias or full URL to one
# row of the catalogue. Errors clearly when the name is ambiguous or unknown.
resolve_dataset <- function(dataset, service = NULL, catalogue = windsor_datasets()) {
  if (grepl("^https?://", dataset)) {
    hit <- catalogue[catalogue$url == dataset, , drop = FALSE]
    if (nrow(hit) == 0) {
      stop("That URL is not in the Windsor catalogue. Use windsor_datasets() to list the known URLs.", call. = FALSE)
    }
    return(hit)
  }

  want <- normalise_name(dataset)
  aliases <- windsor_aliases()
  if (want %in% aliases$alias) {
    want <- aliases$dataset[aliases$alias == want][1]
  }

  catalogue$title_norm <- normalise_name(catalogue$title)
  hit <- catalogue[catalogue$dataset == want | catalogue$title_norm == want, , drop = FALSE]
  catalogue$title_norm <- NULL

  if (!is.null(service)) {
    hit <- hit[hit$service == service, , drop = FALSE]
  }

  if (nrow(hit) == 0) {
    stop(
      "No Windsor dataset called '", dataset, "'. ",
      "Try windsor_search('", dataset, "') to find the closest name.",
      call. = FALSE
    )
  }
  if (nrow(hit) > 1) {
    matches <- paste0("  ", hit$service, " / ", hit$dataset, " (", hit$url, ")", collapse = "\n")
    stop(
      "The name '", dataset, "' matches ", nrow(hit), " datasets. ",
      "Pick one by adding service = \"...\":\n", matches,
      call. = FALSE
    )
  }
  hit[, names(hit) != "title_norm", drop = FALSE]
}
