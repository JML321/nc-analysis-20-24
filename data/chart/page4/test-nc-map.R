library(sf)
library(leaflet)
library(dplyr)
library(htmlwidgets)
library(htmltools)
library(readxl)
library(RColorBrewer)

# Try to load stringr, if it's not available, we'll use a base R function
if (!require(stringr)) {
  print("stringr package not found. Using base R function for title case conversion.")
  to_title_case <- function(x) {
    gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", tolower(x), perl = TRUE)
  }
} else {
  to_title_case <- stringr::str_to_title
}

# Set the path to your zip file and Excel file
zip_path <- "C:\\Users\\justi\\Downloads\\North_Carolina_State_and_County_Boundary_Polygons.zip"
excel_path <- "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\chart\\chart-data.xlsx"

# Create a temporary directory to unzip the files
temp_dir <- tempdir()

# Unzip the file
unzip(zip_path, exdir = temp_dir)

# Read the shapefile
shapefile_path <- file.path(temp_dir, "North_Carolina_State_and_County_Boundary_Polygons.shp")
if (!file.exists(shapefile_path)) {
  stop("Shapefile not found in the temporary directory.")
}
nc_counties <- st_read(shapefile_path)
print("Shapefile read successfully")

# Transform the CRS to WGS84
nc_counties_wgs84 <- st_transform(nc_counties, 4326)
print("Shapefile transformed to WGS84")

# Read the data from the first sheet of the Excel file
excel_data <- read_excel(excel_path, sheet = 1)
print("Excel data read successfully")
print("Excel data preview:")
print(head(excel_data))

# Convert county names in the Excel data to title case to match the shapefile
excel_data$County <- to_title_case(excel_data[[2]])  # Second column for county names
print("County names converted to title case")

# Merge the Excel data with the shapefile data
nc_counties_wgs84 <- nc_counties_wgs84 %>%
  left_join(excel_data, by = c("County" = "County"))

# Extract the data column (column 3) from the merged dataframe
data_column_name <- names(excel_data)[3]
data_column <- nc_counties_wgs84[[data_column_name]]

# Extract the total votes column (column 4) from the merged dataframe
total_votes_column_name <- names(excel_data)[4]
total_votes_column <- nc_counties_wgs84[[total_votes_column_name]]

# Check for any NA values in the data column and handle them
if (any(is.na(data_column))) {
  print("NA values found in the data column. Replacing NAs with 0.")
  data_column[is.na(data_column)] <- 0
  nc_counties_wgs84[[data_column_name]][is.na(nc_counties_wgs84[[data_column_name]])] <- 0
}

# Create custom color palettes for positive and negative values
blue_palette <- c("#CCEAFD", "#92bde0", "#5295cc", "#0F5A8F")  # Light to dark blue
red_palette <- c("#F4CCCC", "#EAA9A9", "#da7171", "#9A282B")  # Light to dark red

# Custom color function
color_function <- function(x) {
  if (is.na(x)) return("#FFFFFF")  # Return white for NA values
  
  if (x >= 0) {
    if (x < 10000) return(red_palette[1])
    else if (x < 20000) return(red_palette[2])
    else if (x < 30000) return(red_palette[3])
    else return(red_palette[4])
  } else {
    x_abs <- abs(x)
    if (x_abs < 10000) return(blue_palette[1])
    else if (x_abs < 20000) return(blue_palette[2])
    else if (x_abs < 100000) return(blue_palette[3])
    else return(blue_palette[4])
  }
}

# Vectorized label function with bold and larger font county names
label_function <- function(county, value, total_votes) {
  total_votes_formatted <- formatC(total_votes, format = "d", big.mark = ",")
  value_formatted <- formatC(abs(value), format = "d", big.mark = ",")
  
  ifelse(value >= 0,
         paste0("<b style='font-size:16px;'>", county, "</b><br/><span style='font-size:12px;'><b>Trump</b> won by <b>", value_formatted, "</b> votes out of <b>", total_votes_formatted, "</b> votes</span>"),
         paste0("<b style='font-size:16px;'>", county, "</b><br/><span style='font-size:12px;'><b>Biden</b> won by <b>", value_formatted, "</b> votes out of <b>", total_votes_formatted, "</b> votes</span>")
  )
}

custom_legend <- tags$div(
  class = "info legend horizontal-legend",
  tags$div(
    class = "legend-title", "Vote Margin",
    tags$div(
      class = "legend-items",
      lapply(seq_along(blue_palette), function(i) {
        tags$div(
          class = "legend-item",
          tags$div(
            class = "color-box",
            style = sprintf("background:%s;", rev(blue_palette)[i])
          ),
          tags$span(class = paste0("label-", i), c("100K", "20K", "10K", "0K")[i])
        )
      }),
      lapply(seq_along(red_palette), function(i) {
        tags$div(
          class = "legend-item",
          tags$div(
            class = "color-box",
            style = sprintf("background:%s;", red_palette[i])
          ),
          if (i != 1) tags$span(class = paste0("label-", i + 4), c("", "10K", "20K", "30K")[i])
        )
      })
    )
  )
)

bounds <- list(
  lng1 = -84.5,  # Western boundary
  lat1 = 33.5,   # Southern boundary
  lng2 = -75.5,  # Eastern boundary
  lat2 = 37.0    # Northern boundary
)

# Print bounds for debugging
print(paste("Bounds set to:", bounds$lng1, bounds$lat1, bounds$lng2, bounds$lat2))

# Define the cities with their coordinates
cities <- data.frame(
  name = c("Charlotte", "Raleigh", "Fayetteville", "Greensboro"),
  lat = c(35.2271, 35.7796, 35.0527, 36.0726),
  lng = c(-80.8431, -78.6382, -78.8784, -79.7920)
)

# Print cities data for debugging
print("Cities data:")
print(cities)

# Calculate the center of the bounding box for the initial view
center_lng <- (bounds$lng1 + bounds$lng2) / 2 
center_lat <- (bounds$lat1 + bounds$lat2) / 2

# Create the leaflet map with custom coloring and legend
map <- leaflet(nc_counties_wgs84, options = leafletOptions(zoomDelta = 0.5, zoomSnap = 0.5, minZoom = 6.5, maxZoom = 9, scrollWheelZoom = FALSE)) %>%
  addPolygons(
    fillColor = ~sapply(get(data_column_name), color_function),
    fillOpacity = 0.7,
    color = "darkgray",
    weight = 1,
    label = ~lapply(label_function(County, get(data_column_name), get(total_votes_column_name)), htmltools::HTML),
    highlightOptions = highlightOptions(
      weight = 2,
      color = "#666",
      fillOpacity = 0.9,
      bringToFront = TRUE
    )
  ) %>%
  addControl(custom_legend, position = "bottomleft") %>%
  setView(lng = center_lng, lat = center_lat, zoom = 6.5) %>%
  setMaxBounds(lng1 = bounds$lng1-2, lat1 = bounds$lat1, lng2 = bounds$lng2+2, lat2 = bounds$lat2) %>%
  addCircleMarkers(data = cities, ~lng, ~lat, radius = 3, 
                   color = "black", fillColor = "black", 
                   fillOpacity = 1, weight = 0, label = ~name)

# Print map bounds after setView and setMaxBounds
print("Map bounds after setView and setMaxBounds:")
print(map$x$limits)

# Adjusting specific city labels
map <- map %>%
  addLabelOnlyMarkers(
    lng = -80.8431, lat = 35.2271, label = "Charlotte", labelOptions = labelOptions(
      noHide = TRUE, textOnly = TRUE, direction = 'auto',
      style = list("font-weight" = "bold", "font-size" = "14px"),
      offset = c(-78, 15)
    )
  ) %>%
  addLabelOnlyMarkers(
    lng = -78.6382, lat = 35.7796, label = "Raleigh", labelOptions = labelOptions(
      noHide = TRUE, textOnly = TRUE, direction = 'auto',
      style = list("font-weight" = "bold", "font-size" = "14px"),
      offset = c(68, -15)
    )
  ) %>%
  addLabelOnlyMarkers(
    lng = -78.8784, lat = 35.0527, label = "Fayetteville", labelOptions = labelOptions(
      noHide = TRUE, textOnly = TRUE, direction = 'auto',
      style = list("font-weight" = "bold", "font-size" = "14px"),
      offset = c(45, -25)
    )
  ) %>%
  addLabelOnlyMarkers(
    lng = -79.7920, lat = 36.0726, label = "Greensboro", labelOptions = labelOptions(
      noHide = TRUE, textOnly = TRUE, direction = 'auto',
      style = list("font-weight" = "bold", "font-size" = "14px"),
      offset = c(40, -22)  # Adjusted to ensure consistent distance
    )
  )

# Save the map as an HTML file with custom CSS for white background and horizontal legend
output_path <- "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\website\\test.html"

saveWidget(map, file = output_path, selfcontained = TRUE, background = "white")
html <- paste(readLines(output_path), collapse = "\n")
html <- gsub('<head>', '<head><style>
  .leaflet-container { background-color: white !important; height: 100vh !important; }
  .horizontal-legend {
    padding: 6px 10px;
    background: transparent !important;
    line-height: 18px;
    color: #555;
    border: none !important;
    box-shadow: none !important;
  }
  .horizontal-legend .legend-title {
    font-weight: bold;
    text-align: center;
    margin-bottom: 5px;
    width: 100%;
    top: -305px; 
  }
  .horizontal-legend .legend-items {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: flex-start;
    flex-wrap: nowrap;
  }
  .horizontal-legend .legend-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    position: relative;
    margin: 0;
  }
  .horizontal-legend .color-box {
    width: 30px;
    height: 20px;
  }
  .horizontal-legend span {
    font-size: 10px;
    position: absolute;
    top: 22px;
    white-space: nowrap;
  }
  .horizontal-legend .label-1 { right: -10px; }
  .horizontal-legend .label-2 { right: -10px; }
  .horizontal-legend .label-3 { right: -10px; }
  .horizontal-legend .label-4 { right: -10px; }
  .horizontal-legend .label-6 { left: -10px; }
  .horizontal-legend .label-7 { left: -10px; }
  .horizontal-legend .label-8 { left: -10px; }

  /* Additional CSS to remove any extra borders or shadows */
  .leaflet-control {
    background: transparent !important;
    border: none !important;
    box-shadow: none !important;
  }
  .leaflet-control-zoom {
    margin-top: 25px !important;  /* Adjust this value to move the buttons lower */
  }
</style>', html)
writeLines(html, output_path)
