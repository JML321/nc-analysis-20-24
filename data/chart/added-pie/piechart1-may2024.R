# Load required libraries
library(ggplot2)
library(dplyr)

s1 <- "Aged In"
s2 <- "Other"
value <- c(0.43, 1.2)

group1 <- paste0(s1, " - ", value[1], "M")
group2 <- paste0(s2, " - ", round(value[2] - value[1], 2), "M")

group1
group2


# Create Data
data <- data.frame(
  group = c(group1, group2),
  value = value
)

# Create a named vector for colors
color_mapping <- c("#66c2a5", "#1f78b4")
names(color_mapping) <- c(group1, group2)

# Compute the position of labels
data <- data %>% 
  arrange(desc(group)) %>%
  mutate(prop = value / sum(data$value) * 100) %>%
  mutate(ypos = cumsum(prop) - 0.5 * prop)

# Basic piechart with adjusted label positions, custom colors, and title
ggplot(data, aes(x = "", y = prop, fill = group)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  theme_void() + 
  theme(
    legend.position = "none",
    plot.title = element_text(vjust = -8.1, hjust = 0.5, size = 16, face = "bold")
  ) +
  
  # Adjust the label positions using position_nudge()
  geom_text(aes(y = ypos, label = group), color = "black", size = 6,
            position = position_nudge(x = 1.00)) +
  
  # Use custom colors with variable group names
  scale_fill_manual(values = color_mapping) +
  
  # Add title
  labs(title = "Nov 2020 to May 2024")