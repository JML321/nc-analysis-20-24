# Load necessary libraries
library(ggplot2)
library(dplyr)
library(gridExtra)
library(scales) # For comma formatting
library(stringr) # For text wrapping
library(grid) # For textGrob

# Data
new_voters <- data.frame(
  Category = c("DEMOCRATIC", "REPUBLICAN", "UNAFFILIATED/OTHER"),
  Total = c(84592, 80593, 106979)
)

added_voters <- data.frame(
  Category = c("DEMOCRATIC", "REPUBLICAN", "UNAFFILIATED/OTHER"),
  Total = c(286492, 291479, 568185)
)

removed_voters <- data.frame(
  Category = c("DEMOCRATIC", "REPUBLICAN", "UNAFFILIATED/OTHER"),
  Total = c(408514, 276822, 366863)
)

# Reorder the Category factor levels
new_voters <- new_voters %>%
  arrange(match(Category, c("DEMOCRATIC", "UNAFFILIATED/OTHER", "REPUBLICAN")))

added_voters <- added_voters %>%
  arrange(match(Category, c("DEMOCRATIC", "UNAFFILIATED/OTHER", "REPUBLICAN")))

removed_voters <- removed_voters %>%
  arrange(match(Category, c("DEMOCRATIC", "UNAFFILIATED/OTHER", "REPUBLICAN")))

# Function to create donut chart without legend
create_donut_chart <- function(data, title, colors) {
  data <- data %>%
    mutate(Fraction = Total / sum(Total),
           ymax = cumsum(Fraction),
           ymin = c(0, head(ymax, n = -1)),
           Label = paste0(comma(Total))) # Use comma formatting
  
  ggplot(data, aes(ymax = ymax, ymin = ymin, xmax = 4, xmin = 2, fill = Category)) +
    geom_rect() +
    coord_polar(theta = "y") +
    xlim(c(1, 5)) + # Adjust xlim to provide more space for text
    theme_void() +
    theme(
      legend.position = "none",
      plot.title = element_text(hjust = 0.5, face = "bold", size = 16), # Center title, make it bold and larger
      plot.margin = margin(t = 10, r = 0, b = 10, l = 0) # Adjust plot margins if needed
    ) +
    geom_text(aes(label = Label, x = 5, y = (ymin + ymax) / 2), size = 4, color = "black", fontface = "bold") + # Adjust x to 5 for further distance and make numbers bold
    scale_fill_manual(values = colors) +
    labs(title = str_wrap(title, width = 15)) # Wrap title text
}

# Define colors
colors <- c("DEMOCRATIC" = "blue", "REPUBLICAN" = "red", "UNAFFILIATED/OTHER" = "gray")

# Create the charts without legends
new_voters_chart <- create_donut_chart(new_voters, "First Time Voters in 2022", colors)
added_voters_chart <- create_donut_chart(added_voters, "Added Voters Since Nov 2020", colors)
removed_voters_chart <- create_donut_chart(removed_voters, "Removed Voters Since Nov 2020", colors)

# Extract the legend from one of the plots
get_legend <- function(plot) {
  tmp <- ggplot_gtable(ggplot_build(plot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

# Create a dummy plot to extract the legend
dummy_plot <- ggplot(new_voters, aes(x = 1, fill = Category)) +
  geom_bar() +
  scale_fill_manual(values = colors) +
  theme(legend.position = "bottom") +
  labs(fill = "Category")

legend <- get_legend(dummy_plot)

# Create text grobs
new_voters_text <- textGrob("No Party Advantage", gp = gpar(fontsize = 12))# , fontface = "bold"))
added_voters_text <- textGrob("No Party Advantage", gp = gpar(fontsize = 12))#, fontface = "bold"))
removed_voters_text <- textGrob("GOP Advantage: 100K+ voters", gp = gpar(fontsize = 12))#, fontface = "bold"))

# Arrange the plots and texts together
combined_plot <- grid.arrange(
  arrangeGrob(new_voters_chart, new_voters_text, ncol = 1, heights = c(8, 1)),
  arrangeGrob(added_voters_chart, added_voters_text, ncol = 1, heights = c(8, 1)),
  arrangeGrob(removed_voters_chart, removed_voters_text, ncol = 1, heights = c(8, 1)),
  ncol = 3
)

# Display the combined plot with the legend
final_plot <- grid.arrange(
  combined_plot,
  legend,
  ncol = 1,
  heights = c(8, 1) # Adjust heights to accommodate the legend
)

# Display the final plot
grid.newpage()
grid.draw(final_plot)
