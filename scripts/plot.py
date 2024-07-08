# import matplotlib.pyplot as plt
# import numpy as np

# # Data
# votes_lost = -817000  # Number for votes lost
# votes_gained = 1140000  # Number for votes gained
# margin_2020 = 74500  # 2020 margin

# # Plot settings
# fig, ax = plt.subplots()

# # Create a half-circle
# size = 0.3
# vals = np.array([abs(votes_lost), abs(votes_gained)])
# colors = ['magenta', 'green']

# # Create the wedges
# wedges, texts = ax.pie(vals, wedgeprops=dict(width=size, edgecolor='w'), startangle=180, colors=colors)

# # Add the black semi-circle in the middle of the pie chart
# ax.add_patch(plt.Circle((0, 0), 0.15, color='black'))

# # Add the texts
# ax.text(0, -0.6, 'NC', ha='center', va='center', fontsize=12, weight='bold')
# ax.text(0.6, 0.2, '+1.14M', ha='center', va='center', fontsize=10, color='black')
# ax.text(-0.6, 0.2, '-817K', ha='center', va='center', fontsize=10, color='black')
# ax.text(0, -0.9, f'{margin_2020/1000:.1f}K\n2020 MARGIN', ha='center', va='center', fontsize=10, color='grey')

# # Draw grey line below the chart
# ax.plot([-1, 1], [-1.2, -1.2], color='grey', lw=1)
# ax.text(0, -1.35, '2020 MARGIN', ha='center', va='center', fontsize=10, color='grey')

# # Ensure equal aspect ratio
# ax.set_aspect('equal')

# # Remove the default axes
# ax.axis('off')

# plt.show()
import os

current_directory = os.getcwd()
print(f"Current working directory: {current_directory}")