#' Search Windsor open datasets by name
#'
#' Searches dataset names, titles and service names. The match is
#' case-insensitive and matches part of a name, so `"ward"` finds the ward
#' boundary, `"bike"` finds bike parking and the bike related layers, and
#' `"trail"` finds the trail and pathway layers.
#'
#' @param pattern Character string to search for.
#' @param service Optional service name to limit the search to, for example
#'   `"transportation"` or `"boundaries"`. See [windsor_services()].
#' @param type Optional type to limit the search to, `"layer"` or `"table"`.
#' @param refresh Logical, passed to [windsor_datasets()]. If `TRUE`, search
#'   the live catalogue instead of the shipped snapshot.
#'
#' @return A tibble in the same format as [windsor_datasets()], with only
#'   the matching rows.
#'
#' @examples
#' \dontrun{
#' windsor_search("ward")
#' windsor_search("bike", service = "transportation")
#' windsor_search("trail")
#' }
#'
#' @export
windsor_search <- function(pattern, service = NULL, type = NULL, refresh = FALSE) {
  cat <- windsor_datasets(refresh = refresh)
  # Match on a word boundary, so "ward" finds the ward boundary but not
  # "forward_sortation_area", which only contains "ward" inside "forward".
  pat <- paste0("\\b", tolower(pattern))
  hit <- grepl(pat, tolower(cat$dataset)) |
    grepl(pat, tolower(cat$title)) |
    grepl(pat, tolower(cat$service))
  out <- cat[hit, , drop = FALSE]
  if (!is.null(service)) {
    out <- out[out$service %in% service, , drop = FALSE]
  }
  if (!is.null(type)) {
    out <- out[out$type %in% type, , drop = FALSE]
  }
  out
}
