\name{windsor_catalogue}
\alias{windsor_catalogue}
\docType{data}
\title{Windsor open data catalogue snapshot}
\format{
A tibble with 227 rows and 9 columns:
\describe{
\item{dataset}{Layer or table name, for example \code{municipal_ward_boundary}.}
\item{title}{Human readable title, for example \code{Municipal Ward Boundary}.}
\item{service}{MapServer service name, for example \code{boundaries}.}
\item{layer_id}{Layer or table id within its service.}
\item{type}{\code{"layer"} or \code{"table"}.}
\item{geometry_type}{ArcGIS geometry type, or \code{NA} for tables.}
\item{url}{Full ArcGIS REST URL for the layer or table.}
\item{display_field}{Display field for the layer.}
\item{n_fields}{Number of fields in the layer or table.}
}
}
\source{
City of Windsor ArcGIS Server, \code{https://mappmycity.ca/arcgis/rest/services/open_data_services},
snapshot taken 2026-11-10. See also \code{inst/extdata/windsor_catalogue.csv}.
}
\description{
Snapshot of the City of Windsor open data catalogue, taken on 2026-11-10
by querying all nine MapServer services in the \code{open_data_services}
folder. This is what \code{\link{windsor_datasets}} returns by default.
Use \code{windsor_datasets(refresh = TRUE)} for the live catalogue.
}
\usage{
windsor_catalogue
}
