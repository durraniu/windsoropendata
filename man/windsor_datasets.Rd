\name{windsor_datasets}
\alias{windsor_datasets}
\title{List all Windsor open datasets}
\usage{
windsor_datasets(refresh = FALSE)
}
\arguments{
\item{refresh}{Logical. If \code{TRUE}, fetch the live catalogue from
\code{https://mappmycity.ca/arcgis/rest/services/open_data_services}.
If the live fetch fails, a warning is issued and the snapshot is returned.}
}
\value{
A tibble with columns \code{dataset}, \code{title}, \code{service},
\code{layer_id}, \code{type} ("layer" or "table"), \code{geometry_type},
\code{url}, \code{display_field} and \code{n_fields}.
}
\description{
Returns a tibble with one row per dataset in the City of Windsor open
data portal, as published on the City's ArcGIS Server at
\code{mappmycity.ca}. By default this returns the snapshot shipped with the
package, taken on 2026-11-10. Set \code{refresh = TRUE} to fetch the live
catalogue from the REST directory instead.
}
\examples{
\dontrun{
windsor_datasets()
windsor_datasets(refresh = TRUE)
}
}
