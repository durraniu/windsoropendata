library(arcgislayers)
wards <- arc_read("https://mappmycity.ca/arcgis/rest/services/open_data_services/boundaries/MapServer/4")
# Peche Island is at the north east, in the Detroit River; keep it in view
png("~/workspace/windsoropendata-build/ward_map.png", width=900, height=900, bg="#0f4c6b")
par(mar=c(0,0,0,0))
plot(sf::st_geometry(wards), col="#a8d0e6", border="white", lwd=2, bg="#0f4c6b")
# highlight Peche Island area with a gold dot roughly at its centroid in EPSG 26917
# Peche Island is near x 355000, y 4700000? use wards bbox to place dot in upper right
points(352000, 4698000, pch=19, col="#f2b705", cex=3)
dev.off()
cat("saved\n")
