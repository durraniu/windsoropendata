#' Windsor Police incident reports
#'
#' Reads police-reported incidents from the Windsor Police Service
#' Incident Dashboard. This is a separate source from the City of
#' Windsor open data portal: it is a public ArcGIS FeatureServer hosted
#' by Windsor Police Service, not one of the 227 datasets in
#' [windsor_datasets()]. It covers the City of Windsor and the Town of
#' Amherstburg, for the last two years, updated daily.
#'
#' Locations are anonymised to the block, for example
#' "2200 BLOCK 2ND CONCESSION RD N". Some incidents and incident types
#' are not displayed, for privacy or investigative reasons, and the
#' police note that all map visualisations should be considered
#' approximate. Motor vehicle collisions are not included in this
#' feed. The "Traffic" category is police traffic incidents, not a
#' collision file.
#'
#' @param category Character vector of incident categories to keep, for
#'   example `"Traffic"` or `c("Theft", "Break and Enter")`. Use
#'   [windsor_police_categories()] for the full list. If `NULL`, all
#'   categories are returned.
#' @param start_date,end_date Start and end dates, as a `"YYYY-MM-DD"`
#'   string, a `Date`, or a `POSIXct`. Both are inclusive, and are
#'   interpreted in the America/Toronto timezone. If `NULL`, no date
#'   filter is applied.
#' @param n_max Maximum number of incidents to return. Defaults to `Inf`
#'   (all incidents). Use a small number, for example `n_max = 5`, to
#'   preview the data. The full download takes about 10 seconds.
#' @param ... Passed to [arcgislayers::arc_read()], for example
#'   `col_select` to read only some columns.
#'
#' @return An `sf` object with point geometry in EPSG 26917 (NAD 1983
#'   UTM Zone 17N), sorted by incident date and time. Columns include
#'   `category`, `location_block`, `occ_num` (occurrence number) and
#'   `incident_datetime`.
#'
#' @examples
#' \dontrun{
#' incidents <- windsor_police_incidents(n_max = 5)
#' traffic <- windsor_police_incidents(category = "Traffic", n_max = 5)
#' recent <- windsor_police_incidents(start_date = "2026-11-01", end_date = "2026-11-10")
#' }
#'
#' @export
windsor_police_incidents <- function(category = NULL, start_date = NULL, end_date = NULL, n_max = Inf, ...) {
  if (!is.null(category)) {
    valid <- windsor_police_categories()
    bad <- setdiff(category, valid)
    if (length(bad) > 0) {
      stop(
        "Unknown incident category: ", paste0("'", bad, "'", collapse = ", "), ". ",
        "Use windsor_police_categories() for the full list.",
        call. = FALSE
      )
    }
  }

  start <- .parse_police_date(start_date, "start_date")
  end <- .parse_police_date(end_date, "end_date")
  if (!is.null(start) && !is.null(end) && start > end) {
    stop("start_date must be on or before end_date.", call. = FALSE)
  }

  where_parts <- character(0)
  if (!is.null(category)) {
    quoted <- paste0("'", gsub("'", "''", category), "'", collapse = ", ")
    where_parts <- c(where_parts, paste0("category IN (", quoted, ")"))
  }
  if (!is.null(start) || !is.null(end)) {
    # The server stores incident_datetime in UTC, while start_date and
    # end_date are interpreted in America/Toronto. Query one extra day
    # on each side from the server, then filter on the local date in R,
    # so a date filter means the local calendar date, not the UTC date.
    server_start <- if (is.null(start)) NULL else start - 1
    server_end <- if (is.null(end)) NULL else end + 2
    if (!is.null(server_start)) {
      where_parts <- c(where_parts, paste0("incident_datetime >= TIMESTAMP '", server_start, " 00:00:00'"))
    }
    if (!is.null(server_end)) {
      where_parts <- c(where_parts, paste0("incident_datetime < TIMESTAMP '", server_end, " 00:00:00'"))
    }
  }
  where <- if (length(where_parts) == 0) NULL else paste(where_parts, collapse = " AND ")

  # When a date filter is present, ask the server for all matching rows
  # and apply n_max after the local date filter in R, so n_max counts
  # the rows actually returned, not rows that fall outside the dates.
  server_n_max <- if (is.null(start) && is.null(end)) n_max else Inf
  out <- if (is.null(where)) {
    arcgislayers::arc_read(windsor_police_url, n_max = server_n_max, ...)
  } else {
    arcgislayers::arc_read(windsor_police_url, where = where, n_max = server_n_max, ...)
  }

  if (!is.null(start) || !is.null(end)) {
    local_date <- as.Date(out$incident_datetime, tz = "America/Toronto")
    keep <- rep(TRUE, nrow(out))
    if (!is.null(start)) keep <- keep & !is.na(local_date) & local_date >= start
    if (!is.null(end)) keep <- keep & !is.na(local_date) & local_date <= end
    out <- out[keep, , drop = FALSE]
  }

  out <- out[order(out$incident_datetime), , drop = FALSE]
  if (is.finite(n_max) && nrow(out) > n_max) {
    out <- out[seq_len(n_max), , drop = FALSE]
  }
  out
}

#' List Windsor Police incident categories
#'
#' @return A character vector of the 17 incident categories used by the
#'   Windsor Police Service Incident Dashboard, as of 2026-11-10.
#'
#' @examples
#' \dontrun{
#' windsor_police_categories()
#' }
#'
#' @export
windsor_police_categories <- function() {
  c(
    "Traffic", "Theft", "Fraud", "Mischief", "Assault",
    "Break and Enter", "Threats/Harassment",
    "Impaired Operation Motor Veh", "Robbery",
    "Possession Stolen Property", "Sexual Violations", "Other",
    "Arson", "Offensive Weapons", "Controlled Drug",
    "Provincial Statutes", "Federal Statutes"
  )
}

# Parse a user supplied start or end date for windsor_police_incidents().
# Returns a Date, or NULL when the input is NULL.
.parse_police_date <- function(x, arg) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, "POSIXt")) {
    return(as.Date(x, tz = "America/Toronto"))
  }
  if (inherits(x, "Date")) {
    return(x)
  }
  if (is.character(x) && length(x) == 1) {
    parsed <- suppressWarnings(as.Date(x))
    if (!is.na(parsed)) {
      return(parsed)
    }
  }
  stop(arg, " must be a 'YYYY-MM-DD' string, a Date, or a POSIXct.", call. = FALSE)
}
