#' windsoropendata: Read City of Windsor Open Data in R
#'
#' A thin wrapper around [arcgislayers::arc_read()] for the City of Windsor
#' open data portal (<https://open-data-portal-citywindsor.hub.arcgis.com/>).
#' The portal is an ArcGIS Hub site backed by the City's own ArcGIS Server
#' at `mappmycity.ca`, so the city is in the server name, not in the URL path.
#'
#' Use [windsor_datasets()] to list what is available, [windsor_search()] to
#' find a dataset by name, and [windsor_get()] to read one by its short name,
#' for example `windsor_get("ward_boundaries")`. Live traffic speeds and
#' incidents come from the TomTom Traffic API instead, with
#' [windsor_tomtom_flow()] and [windsor_tomtom_incidents()], which need
#' a free TomTom API key in the `TOMTOM_API_KEY` environment variable.
#'
#' @keywords internal
"_PACKAGE"

#' Base URL for the Windsor ArcGIS REST services
#'
#' All Windsor open data lives under this folder on the City's server.
#' @keywords internal
windsor_base_url <- "https://mappmycity.ca/arcgis/rest/services/open_data_services"

#' URL for the Windsor Police Service Incident Reporting FeatureServer
#'
#' A separate source from the City open data portal, hosted by Windsor
#' Police Service on ArcGIS Online. Used by
#' [windsor_police_incidents()].
#' @keywords internal
windsor_police_url <- "https://services5.arcgis.com/QFS1kYToUwENLBg0/arcgis/rest/services/Incident_Reporting/FeatureServer/0"

#' The nine MapServer services in the Windsor open data folder
#' @keywords internal
windsor_service_names <- c(
  "boundaries",
  "communityrecreation",
  "demographics",
  "governmentservices",
  "infrastructure",
  "parksandenvironment",
  "planningdevelopment",
  "propertyparcels",
  "transportation"
)
