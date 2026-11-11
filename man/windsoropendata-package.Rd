\name{windsoropendata-package}
\alias{windsoropendata-package}
\alias{windsoropendata}
\docType{package}
\title{windsoropendata: Read City of Windsor Open Data in R}
\description{
A thin wrapper around \code{\link[arcgislayers:arc_read]{arcgislayers::arc_read}} for the City of Windsor
open data portal (\url{https://open-data-portal-citywindsor.hub.arcgis.com/}).
The portal is an ArcGIS Hub site backed by the City's own ArcGIS Server
at \code{mappmycity.ca}, so the city is in the server name, not in the URL path.
}
\details{
Use \code{\link{windsor_datasets}} to list what is available,
\code{\link{windsor_search}} to find a dataset by name, and
\code{\link{windsor_get}} to read one by its short name,
for example \code{windsor_get("ward_boundaries")}.
}
\author{
Umair Durrani
}
