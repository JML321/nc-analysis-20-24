# Load required libraries
library(ggplot2)
library(dplyr)
library(ggpattern)
# Define group names (you can change these)
group1 <- "Nov 2020 to May 2024"
group2 <- "Projected May 2024 to Nov 2024"
# Create sample data
data <- data.frame(
  category = c(rep("A", 2), rep("B", 2), "C"),
  subgroup = c(group1, group2, group1, group2, "2020 Margin"),
  value = c(1.146, .472,  # Group A
            .433, .117,  # Group B
            0.074)   # Group C
)
# Set the order of the subgroups
data$subgroup <- factor(data$subgroup, levels = c(group1, group2, "2020 Margin"))
# Create the plot
ggplot(data, aes(x = category, y = value, fill = subgroup)) +
  geom_bar_pattern(
    aes(pattern = subgroup),
    stat = "identity", 
    position = position_stack(reverse = TRUE), 
    width = 0.7,
    pattern_fill = "#E0E0E0",  # Light gray color for the lines
    pattern_angle = 135,  # Right-to-left diagonal
    pattern_density = 0.03,  # Reduced density for more sparse lines
    pattern_spacing = 0.02,  # Slightly reduced spacing for thinner lines
    pattern_key_scale_factor = 0.6
  ) +
  scale_fill_manual(values = c("#2E8B57", "#C1FFC1", "#006400")) +  # Medium green, Lighter green, Dark green
  scale_pattern_manual(values = c("none", "stripe", "none")) +
  theme_minimal() +
  labs(
       y = "Number of Voters (Millions)") +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    legend.position = "bottom",
    axis.title.x = element_blank(),
    legend.title = element_blank()
  ) +
  scale_x_discrete(
    limits = c("A", "B", "C"),
    labels = c("Added", "Aged In", "2020 Margin")
  )