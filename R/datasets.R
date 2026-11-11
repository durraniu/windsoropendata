#' List all Windsor open datasets
#'
#' Returns a tibble with one row per dataset in the City of Windsor open
#' data portal, as published on the City's ArcGIS Server at
#' `mappmycity.ca`. By default this returns the snapshot shipped with the
#' package, taken on 2026-11-10. Set `refresh = TRUE` to fetch the live
#' catalogue from the REST directory instead.
#'
#' @param refresh Logical. If `TRUE`, fetch the live catalogue from
#'   `https://mappmycity.ca/arcgis/rest/services/open_data_services`.
#'   If the live fetch fails, a warning is issued and the snapshot is returned.
#'
#' @return A tibble with columns `dataset`, `title`, `service`, `layer_id`,
#'   `type` ("layer" or "table"), `geometry_type`, `url`, `display_field`
#'   and `n_fields`.
#'
#' @examples
#' \dontrun{
#' windsor_datasets()
#' windsor_datasets(refresh = TRUE)
#' }
#'
#' @export
windsor_datasets <- function(refresh = FALSE) {
  if (!isTRUE(refresh)) {
    return(windsor_catalogue)
  }
  live <- tryCatch(
    windsor_refresh(),
    error = function(e) {
      warning("Live catalogue fetch failed (", conditionMessage(e), "). Returning the shipped snapshot.", call. = FALSE)
      NULL
    }
  )
  if (is.null(live)) windsor_catalogue else live
}

#' List the nine Windsor open data services
#'
#' @return A tibble with one row per MapServer service, with the number of
#'   datasets, layers and tables in each.
#'
#' @examples
#' \dontrun{
#' windsor_services()
#' }
#'
#' @export
windsor_services <- function() {
  cat <- windsor_datasets()
  services <- sort(unique(cat[["service"]]))
  tibble::tibble(
    service = services,
    n_datasets = vapply(services, function(s) sum(cat[["service"]] == s), integer(1)),
    layer = vapply(services, function(s) sum(cat[["service"]] == s & cat[["type"]] == "layer"), integer(1)),
    table = vapply(services, function(s) sum(cat[["service"]] == s & cat[["type"]] == "table"), integer(1))
  )
}

#' Fetch the live Windsor catalogue from the ArcGIS REST directory
#'
#' Queries each of the nine MapServer services under
#' `open_data_services` with `?f=json`, then queries each layer and table
#' for its geometry type, display field and field list. This is what
#' `windsor_datasets(refresh = TRUE)` uses.
#'
#' @return A tibble in the same format as [windsor_datasets()].
#'
#' @examples
#' \dontrun{
#' windsor_refresh()
#' }
#'
#' @export
windsor_refresh <- function() {
  rows <- list()
  for (svc in windsor_service_names) {
    url <- paste0(windsor_base_url, "/", svc, "/MapServer?f=json")
    resp <- httr2::request(url) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()
    j <- httr2::resp_body_json(resp, simplifyVector = FALSE)
    for (lyr in j$layers) {
      rows[[length(rows) + 1]] <- list(service = svc, layer_id = lyr$id, name = lyr$name, type = "layer")
    }
    for (tbl in j$tables %||% list()) {
      rows[[length(rows) + 1]] <- list(service = svc, layer_id = tbl$id, name = tbl$name, type = "table")
    }
  }
  base <- dplyr::bind_rows(rows)
  details <- lapply(seq_len(nrow(base)), function(i) {
    row <- base[i, ]
    url <- paste0(windsor_base_url, "/", row$service, "/MapServer/", row$layer_id, "?f=json")
    resp <- httr2::request(url) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()
    j <- httr2::resp_body_json(resp, simplifyVector = FALSE)
    fields <- ""
    n_fields <- NA_integer_
    if (!is.null(j$fields)) {
      fn <- vapply(j$fields, function(f) f$name %||% "", character(1))
      fields <- paste(fn, collapse = ", ")
      n_fields <- length(fn)
    }
    tibble::tibble(
      dataset = row$name,
      title = pretty_title(row$name),
      service = row$service,
      layer_id = as.integer(row$layer_id),
      type = row$type,
      geometry_type = j$geometryType %||% NA_character_,
      url = paste0(windsor_base_url, "/", row$service, "/MapServer/", row$layer_id),
      display_field = j$displayField %||% NA_character_,
      n_fields = n_fields
    )
  })
  dplyr::bind_rows(details)
}
