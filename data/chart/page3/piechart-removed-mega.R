# Load required libraries
library(ggplot2)
library(dplyr)
library(patchwork)

# Function to create a pie chart
create_pie_chart <- function(value, color_mapping, title) {
  s1 <- "Deceased"
  s2 <- "Other"
  group1 <- s1
  group2 <- s2
  
  value <- c(value[1],value[2]-value[1])
  
  # Create Data
  data <- data.frame(
    group = c(group1, group2),
    value = value
  )
  
  # Compute the position of labels
  data <- data %>% 
    arrange(desc(group)) %>%
    mutate(prop = value / sum(data$value) * 100) %>%
    mutate(ypos = cumsum(prop) - 0.5 * prop)
  
  
  
  # Create the pie chart
  ggplot(data, aes(x = "", y = prop, fill = group)) +
    geom_bar(stat = "identity", width = 1, color = "white") +
    coord_polar("y", start = 0) +
    theme_void() + 
    theme(
      legend.position = "none",
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
    ) +
    geom_text(aes(y = ypos, label = paste0(round(value, 2), "M")), color = "black", size = 5,
              position = position_nudge(x = 0.9)) +
    scale_fill_manual(values = color_mapping, name = "# of Voters") +  # Add legend title
    labs(title = title)
}

# Define colors
orange <- "#fc8d62"
purple <- "#7570b3"

# Create each pie chart with the same colors
chart1 <- create_pie_chart(c(0.28, 1.01), c(orange, purple), "Nov 2020 to May 2024")
chart2 <- create_pie_chart(c(0.26, 1.13), c(orange, purple), "Nov 2016 to Nov 2020")
chart3 <- create_pie_chart(c(0.25, 0.95), c(orange, purple), "Nov 2012 to Nov 2016")
chart4 <- create_pie_chart(c(0.23, 0.82), c(orange, purple), "Nov 2008 to Nov 2012")

# Combine the charts into a 2x2 grid
combined_chart <- (chart1 + chart2) / (chart3 + chart4) +
  plot_layout(guides = 'collect') &
  theme(
    legend.position = "right",
    legend.box.margin = margin(0, 0, 0, -10),  # Adjust the left margin of the legend
    legend.margin = margin(0, 0, 0, -10),  # Further adjust the legend margin
    legend.text = element_text(size = 10),  # Increase legend text size
    legend.title = element_text(size = 12, face = "bold"),  # Make legend title bold and larger
    legend.key.size = unit(0.6, "cm")  # Increase the size of the color boxes in the legend
  )

# Add a title to the combined chart
final_chart <- combined_chart   

# Display the combined chart
print(final_chart)

# If you want to save the chart, uncomment the following line:
# ggsave("combined_pie_charts_with_legend.png", final_chart, width = 12, height = 10, dpi = 300)