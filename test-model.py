import pandas as pd
from sklearn.linear_model import LinearRegression, Lasso, Ridge
from sklearn.metrics import mean_squared_error
import numpy as np

# File Paths
added_training_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\added-training.xlsx"
removed_training_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\removed-training.xlsx"
added_inference_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\added-inference.xlsx"
removed_inference_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\removed-inference.xlsx"
new_added_inference_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\new-added-inference.xlsx"
new_removed_inference_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\new-removed-inference.xlsx"

# Load Data
added_training_df = pd.read_excel(added_training_path)
removed_training_df = pd.read_excel(removed_training_path)
added_inference_df = pd.read_excel(added_inference_path)
removed_inference_df = pd.read_excel(removed_inference_path)

# Prepare Data
input_columns = ['d0', 'd1', 'd2']
target_columns = ['f0', 'f1', 'i0', 'i1']

def prepare_data(df):
    X = df[input_columns]
    y0 = (df['f0'] - df['i0']) / df['i0']
    y1 = (df['f1'] - df['i1']) / df['i1']
    return X, y0, y1

X_added, y0_added, y1_added = prepare_data(added_training_df)
X_removed, y0_removed, y1_removed = prepare_data(removed_training_df)

# Train Models
def train_model(X, y):
    model = LinearRegression()
    model.fit(X, y)
    return model

model_y0_added = train_model(X_added, y0_added)
model_y1_added = train_model(X_added, y1_added)
model_y0_removed = train_model(X_removed, y0_removed)
model_y1_removed = train_model(X_removed, y1_removed)

# Print Coefficients
print("Coefficients for added data (y0):", model_y0_added.coef_)
print("Coefficients for added data (y1):", model_y1_added.coef_)
print("Coefficients for removed data (y0):", model_y0_removed.coef_)
print("Coefficients for removed data (y1):", model_y1_removed.coef_)

# Model Goals for Output
def calculate_metrics(pred, actual):
    delta = pred - actual
    avg_delta = np.mean(delta / actual)
    std_delta = np.std(delta / actual)
    total_sum = np.sum(delta)
    min_delta = np.min(delta)
    max_delta = np.max(delta)
    return avg_delta, std_delta, total_sum, min_delta, max_delta

def evaluate_model(model_y0, model_y1, X, df, description):
    pred_y0 = model_y0.predict(X) * df['i0'] + df['i0']
    pred_y1 = model_y1.predict(X) * df['i1'] + df['i1']

    avg_delta_y0, std_delta_y0, total_sum_y0, min_delta_y0, max_delta_y0 = calculate_metrics(pred_y0, df['i0'])
    avg_delta_y1, std_delta_y1, total_sum_y1, min_delta_y1, max_delta_y1 = calculate_metrics(pred_y1, df['i1'])

    print(f"Evaluation for {description}:")
    print(f"Target Sum for f0-i0: 360,000 to 420,000 | Actual: {total_sum_y0}")
    print(f"Target Sum for f1-i1: 49,000 to 105,000 | Actual: {total_sum_y1}")
    print(f"Target Avg Delta for f0-i0: 5% ± 10% | Actual: {avg_delta_y0:.2%} ± {std_delta_y0:.2%}")
    print(f"Target Avg Delta for f1-i1: 17% ± 11% | Actual: {avg_delta_y1:.2%} ± {std_delta_y1:.2%}")

    return pred_y0, pred_y1

pred_y0_added, pred_y1_added = evaluate_model(model_y0_added, model_y1_added, added_inference_df[input_columns], added_inference_df, "Added Data")
pred_y0_removed, pred_y1_removed = evaluate_model(model_y0_removed, model_y1_removed, removed_inference_df[input_columns], removed_inference_df, "Removed Data")

# Save Predictions to New Excel Files
def save_predictions(df, pred_y0, pred_y1, path):
    df['f0_pred'] = pred_y0
    df['f1_pred'] = pred_y1
    df.to_excel(path, index=False)

save_predictions(added_inference_df, pred_y0_added, pred_y1_added, new_added_inference_path)
save_predictions(removed_inference_df, pred_y0_removed, pred_y1_removed, new_removed_inference_path)
