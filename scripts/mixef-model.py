import numpy as np
import pandas as pd
import tensorflow as tf
import tensorflow_probability as tfp
import openpyxl

# Function to run the process for each dataset and target column
def run_model(file_path, target_column, initial_coefficients, intercept):
    # Load Data
    df = pd.read_excel(file_path)

    # Prepare Data
    input_columns = ['d0', 'd1', 'd2']
    df['intercept'] = 1.0
    input_columns_with_intercept = ['intercept'] + input_columns

    X = df[input_columns_with_intercept].astype(np.float32).values
    target_index = int(target_column[-1])  # Assuming target_column is 'f0' or 'f1'
    y = ((df[target_column] - df[f'i{target_index}']) / df[f'i{target_index}']).astype(np.float32).values

    # County encoding
    counties = df['County'].astype('category').cat.codes.values.astype(np.int32)
    n_counties = len(np.unique(counties))

    # Known coefficients
    known_coefficients = np.array([intercept] + initial_coefficients, dtype=np.float32)

    # Create extremely tight priors
    prior_scale = 1e-2
    fixed_effects_prior = tfp.distributions.MultivariateNormalDiag(
        loc=known_coefficients,
        scale_diag=[prior_scale] * len(known_coefficients)
    )

    random_effects_prior = tfp.distributions.Normal(loc=0., scale=prior_scale)

    # Define the variational posteriors
    fixed_effects_posterior = tfp.distributions.MultivariateNormalDiag(
        loc=tf.Variable(known_coefficients, dtype=tf.float32),
        scale_diag=tf.Variable([prior_scale] * len(known_coefficients), dtype=tf.float32)
    )

    random_effects_posterior = tfp.distributions.Normal(
        loc=tf.Variable(tf.zeros(n_counties, dtype=tf.float32)),
        scale=tf.Variable(tf.ones(n_counties, dtype=tf.float32) * prior_scale)
    )

    # Define the model
    def model(X, fixed_coeffs, random_coeffs, counties):
        return tf.linalg.matvec(X, fixed_coeffs) + tf.gather(random_coeffs, counties)

    # Define the loss function
    def loss_fn():
        fixed_coeffs = fixed_effects_posterior.sample()
        random_coeffs = random_effects_posterior.sample()
        predicted = model(X, fixed_coeffs, random_coeffs, counties)
        reconstruction_loss = tf.reduce_mean(tf.square(y - predicted))
        kl_divergence_fixed = tfp.distributions.kl_divergence(fixed_effects_posterior, fixed_effects_prior)
        kl_divergence_random = tf.reduce_sum(tfp.distributions.kl_divergence(random_effects_posterior, random_effects_prior))
        return reconstruction_loss + kl_divergence_fixed + kl_divergence_random

    # Optimize
    optimizer = tf.keras.optimizers.Adam(learning_rate=1e-5)

    @tf.function
    def train_step():
        with tf.GradientTape() as tape:
            loss = loss_fn()
        gradients = tape.gradient(loss, fixed_effects_posterior.trainable_variables + random_effects_posterior.trainable_variables)
        optimizer.apply_gradients(zip(gradients, fixed_effects_posterior.trainable_variables + random_effects_posterior.trainable_variables))
        return loss

    for step in range(5000):
        loss = train_step()

    # Sample from the posterior
    fixed_samples = fixed_effects_posterior.sample(1000)

    mean_fixed_samples = tf.reduce_mean(fixed_samples, axis=0).numpy()

    return mean_fixed_samples, known_coefficients

# Coefficients for each case
coefficients_and_intercepts = {
    "added_f0": ([9.91035196e-05, -2.27601966e-03, 1.62435112e-01], 0.43680339768592946),
    "added_f1": ([5.30625148e-05, -3.36201453e-03, 5.53690929e-01], 0.21407100207017415),
    "removed_f0": ([-1.12734129e-05, -4.23893093e-04, 4.84895150e-03], 0.06869529989858339),
    "removed_f1": ([3.84936967e-05, -2.47828483e-04, -7.77327803e-02], 0.187181164996834),
}

# File paths
added_training_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\added-training.xlsx"
removed_training_path = "C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\removed-training.xlsx"

# Results storage
results = []

# Run model for each case and store results
for key, (coefficients, intercept) in coefficients_and_intercepts.items():
    if "added" in key:
        results.append(run_model(added_training_path, key.split('_')[1], coefficients, intercept))
    else:
        results.append(run_model(removed_training_path, key.split('_')[1], coefficients, intercept))

# Prepare data for saving
data = []
for i, result in enumerate(results):
    mean_fixed_samples, known_coefficients = result
    data.append(np.concatenate((mean_fixed_samples, known_coefficients)))

# Convert results to DataFrame
columns = ["Mean Intercept", "Mean d0", "Mean d1", "Mean d2", "Known Intercept", "Known d0", "Known d1", "Known d2"]
results_df = pd.DataFrame(data, columns=columns, index=[
    "added_f0", "added_f1", "removed_f0", "removed_f1"
])

# Save results to Excel
results_df.to_excel("C:\\Users\\justi\\Dropbox\\Projects\\Politics\\nc-data-analysis\\data\\coefficients_results.xlsx")
