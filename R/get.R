#' Read a Windsor open dataset by name
#'
#' Reads one dataset from the City of Windsor open data portal without
#' typing its full ArcGIS REST URL. Give a short name, a title, an alias,
#' or a full URL, and the package looks up the URL and reads it with
#' [arcgislayers::arc_read()].
#'
#' @param dataset Dataset name, title, alias or full REST URL. Examples:
#'   `"ward_boundaries"`, `"municipal_ward_boundary"`, `"Ward Boundaries"`,
#'   `"peche_island_pathway"`, `"street_centreline"`. Three names are
#'   used by more than one service (`hydrant`, `electric_vehicle_charger`
#'   and `public_property_obstruction`); for those, add `service`.
#' @param service Optional service name, for example `"boundaries"` or
#'   `"transportation"`. Required only when the dataset name is ambiguous.
#' @param n_max Maximum number of features to read. Defaults to `Inf`
#'   (all features). Use a small number, for example `n_max = 5`, to
#'   preview a large layer such as `street_centreline`.
#' @param ... Passed to [arcgislayers::arc_read()], for example
#'   `col_select` to read only some columns.
#'
#' @return An `sf` object for a spatial layer, or a data frame for a table.
#'   Spatial data is in EPSG 26917 (NAD 1983 UTM Zone 17N), the City's
#'   native projection.
#'
#' @examples
#' \dontrun{
#' wards <- windsor_get("ward_boundaries")
#' peche <- windsor_get("peche_island_pathway")
#' streets <- windsor_get("street_centreline", n_max = 5)
#' }
#'
#' @export
windsor_get <- function(dataset, service = NULL, n_max = Inf, ...) {
  row <- resolve_dataset(dataset, service = service)
  arcgislayers::arc_read(row$url, n_max = n_max, ...)
}
