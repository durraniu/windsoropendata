\name{windsor_search}
\alias{windsor_search}
\title{Search Windsor open datasets by name}
\usage{
windsor_search(pattern, service = NULL, type = NULL, refresh = FALSE)
}
\arguments{
\item{pattern}{Character string to search for.}
\item{service}{Optional service name to limit the search to, for example
\code{"transportation"} or \code{"boundaries"}. See \code{\link{windsor_services}}.}
\item{type}{Optional type to limit the search to, \code{"layer"} or \code{"table"}.}
\item{refresh}{Logical, passed to \code{\link{windsor_datasets}}. If \code{TRUE}, search
the live catalogue instead of the shipped snapshot.}
}
\value{
A tibble in the same format as \code{\link{windsor_datasets}}, with only
the matching rows.
}
\description{
Searches dataset names, titles and service names. The match is
case-insensitive and matches part of a name, so \code{"ward"} finds the ward
boundary, \code{"bike"} finds bike parking and the bike related layers, and
\code{"trail"} finds the trail and pathway layers.
}
\examples{
\dontrun{
windsor_search("ward")
windsor_search("bike", service = "transportation")
windsor_search("trail")
}
}
