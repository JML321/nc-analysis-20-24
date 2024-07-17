# Load required libraries
library(ggplot2)
library(geomtextpath)
library(grid)

# Function to create points for a specified segment of a circle
create_circle_segment <- function(center = c(0, 0), radius = 1, start_angle = 0, end_angle = pi/2, n = 1000) {
  theta <- seq(start_angle, end_angle, length.out = n)
  x <- c(center[1], center[1] + radius * cos(theta), center[1])
  y <- c(center[2], center[2] + radius * sin(theta), center[2])
  return(data.frame(x = x, y = y))
}

# Function to add curved text to the plot
add_curved_text <- function(text, radius = 1.5, curvature = pi/3, size = 5, angle = pi/3, position = c(0, 0)) {
  theta <- seq(-curvature/2, curvature/2, length.out = 100)
  x <- position[1] + radius * cos(theta + angle)
  y <- position[2] + radius * sin(theta + angle)
  return(data.frame(x = x, y = y, label = rep(text, 100), size = size))
}

# Create the quarter circle points for 0 to pi/2 (green)
quarter_circle_1 <- create_circle_segment(center = c(0, 0), radius = 1, start_angle = 0, end_angle = pi/2, n = 1000)
quarter_circle_1$group <- "Main Segment"

# Create the lighter green extended region
quarter_circle_1_light <- create_circle_segment(center = c(0, 0), radius = 1.41, start_angle = 0, end_angle = pi/2, n = 1000)
quarter_circle_1_light$group <- "Extended Segment"

# Create the quarter circle points for pi/2 to pi (purple), smaller and touching the green one
radius_2 <- 0.92  # Smaller radius for the purple segment
quarter_circle_2 <- create_circle_segment(center = c(0, 0), radius = radius_2, start_angle = pi/2, end_angle = pi, n = 1000)
quarter_circle_2$group <- "Secondary Segment"

# Create the lighter purple extended region
quarter_circle_2_light <- create_circle_segment(center = c(0, 0), radius = 0.99, start_angle = pi/2, end_angle = pi, n = 1000)
quarter_circle_2_light$group <- "Extended Secondary"

# Create the semicircle points for the black semicircle
black_semicircle <- create_circle_segment(center = c(0, 0), radius = 0.06, start_angle = 0, end_angle = pi, n = 1000)
black_semicircle$group <- "Center"

# Create the dotted semicircle (curved part only)
dotted_semicircle <- data.frame(
  length <- 0.64,
  x = length * cos(seq(0, pi, length.out = 1000)),
  y = length * sin(seq(0, pi, length.out = 1000))
)
dotted_semicircle$group <- "Dotted Line"

# Create data for the "74.5K" text below the black semicircle
text_74_5K <- data.frame(x = 0, y = -0.09, label = "74.5K")

# Create data for the "NC" text
text_NC <- data.frame(x = 0, y = 1.55, label = "Overall Change")

# Create data for the grey line and "2020 Margin" text
line_start <- data.frame(x = 0, y = -0.17)
line_end <- data.frame(x = 0, y = -0.4)
text_margin <- data.frame(x = 0, y = -0.45, label = "2020 Presidential Margin")

# Create the curved text data
delta <- 0.15
curved_text1 <- add_curved_text("1.6M Voters Added", radius = 1.41 + delta, curvature = pi/3, size = 5, angle = pi/3, position = c(0, 0))
curved_text2 <- add_curved_text("1.0M Voters Removed", radius = 1.00 + delta, curvature = pi/3, size = 5, angle = 3*pi/8 + pi/3, position = c(0, 0))

# Create the combined plot
p <- ggplot() +
  geom_polygon(data = quarter_circle_1_light, aes(x, y, fill = group)) +
  geom_polygon(data = quarter_circle_2_light, aes(x, y, fill = group)) +
  geom_polygon(data = quarter_circle_1, aes(x, y, fill = group)) +
  geom_polygon(data = quarter_circle_2, aes(x, y, fill = group)) +
  geom_polygon(data = black_semicircle, aes(x, y, fill = group)) +
  geom_path(data = dotted_semicircle, aes(x, y, color = group), size = 0.7, linetype = "dotted") +
  geom_text(data = text_74_5K, aes(x = x, y = y, label = label), 
            size = 5, vjust = 0.5, hjust = 0.5, color = "black", fontface = "bold") +
   geom_text(data = text_NC, aes(x = x, y = y, label = label), 
             size = 6, vjust = 0.5, hjust = 0.5, color = "black", fontface = "bold") +  # New NC text
  geom_segment(aes(x = line_start$x, y = line_start$y, xend = line_end$x, yend = line_end$y), 
               color = "grey", size = 1) +
  geom_text(data = text_margin, aes(x = x, y = y, label = label), 
            size = 5, vjust = 0.5, hjust = 0.5, color = "black") +
  geom_textpath(data = curved_text1, aes(x = x, y = y, label = label), 
                text_only = TRUE, color = "black", size = curved_text1$size[1], vjust = 0.1, hjust = 0.5) +
  geom_textpath(data = curved_text2, aes(x = x, y = y, label = label), 
                text_only = TRUE, color = "black", size = curved_text2$size[1], vjust = 0.1, hjust = 0.5) +
  coord_fixed(ratio = 1) +
  scale_fill_manual(values = c("Main Segment" = "#82D8B4",
                               "Extended Segment" = "#00BD8D",
                               "Secondary Segment" = "#E56EC0",
                               "Extended Secondary" = "#D62AAB",
                               "Center" = "black"),
                    labels = c("Nov '20 - May '24", 
                               "Projected May '24 - Nov '24", 
                               "Nov '20 - May '24",
                               "Projected May '24 - Nov '24", "")) +
  scale_color_manual(values = c("Dotted Line" = "black"),
                     labels = c("10% of 2020 Registered")) +
  guides(fill = guide_legend(override.aes = list(
    fill = c("#82D8B4", "#00BD8D", "#E56EC0", "#D62AAB", NA),
    linetype = c("solid", "solid", "solid", "solid", "dotted")),
    title = "hi"),
    color = guide_legend(override.aes = list(
      linetype = "dotted",
      fill = NA),
      order = 1,
      title = NULL)) +
  theme_void() +
  theme(panel.background = element_rect(fill = "white", colour = "white"),
        legend.position = "right",
        legend.box = "vertical",
        legend.margin = margin(t = 0, r = 10, b = 0, l = 10),
        legend.title = element_blank())  # Ensure the legend title is blank

# Display the plot
print(p)
