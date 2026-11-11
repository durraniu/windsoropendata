#' Windsor open data catalogue snapshot
#'
#' Snapshot of the City of Windsor open data catalogue, taken on 2026-11-10
#' by querying all nine MapServer services in the `open_data_services`
#' folder. This is what [windsor_datasets()] returns by default.
#'
#' @format A tibble with 227 rows and 9 columns:
#' \describe{
#'   \item{dataset}{Layer or table name, for example `municipal_ward_boundary`.}
#'   \item{title}{Human readable title, for example `Municipal Ward Boundary`.}
#'   \item{service}{MapServer service name, for example `boundaries`.}
#'   \item{layer_id}{Layer or table id within its service.}
#'   \item{type}{`"layer"` or `"table"`.}
#'   \item{geometry_type}{ArcGIS geometry type, or `NA` for tables.}
#'   \item{url}{Full ArcGIS REST URL for the layer or table.}
#'   \item{display_field}{Display field for the layer.}
#'   \item{n_fields}{Number of fields in the layer or table.}
#' }
#' @source City of Windsor ArcGIS Server,
#'   `https://mappmycity.ca/arcgis/rest/services/open_data_services`,
#'   snapshot taken 2026-11-10. See also `inst/extdata/windsor_catalogue.csv`.
"windsor_catalogue"
