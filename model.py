import pandas as pd
import numpy as np
import tensorflow as tf
import tensorflow_probability as tfp
from sklearn.preprocessing import StandardScaler

# Abbreviations for TensorFlow Probability modules
tfd = tfp.distributions
tfb = tfp.bijectors

# Step 1: Load and Preprocess Data
def load_and_preprocess_data(train_path):
    df = pd.read_excel(train_path)
    print("Columns in the DataFrame:", df.columns)
    
    features = df[['d0', 'd1', 'd2']]
    
    # Calculate relative changes
    df['change_f0'] = (df['f0'] - df['i0']) / df['i0']
    df['change_f1'] = (df['f1'] - df['i1']) / df['i1']
    
    targets = df[['change_f0', 'change_f1']]
    
    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)
    
    df_scaled = pd.DataFrame(features_scaled, columns=['d0', 'd1', 'd2'])
    df_scaled['county'] = df['County']  # Ensure this matches the actual column name
    df_scaled['year'] = df['Year']
    df_scaled[['change_f0', 'change_f1']] = targets
    df_scaled[['i0', 'i1']] = df[['i0', 'i1']]  # Keep original i0 and i1 for later use

    return df_scaled, scaler

# Step 2: Define the Linear Mixed-Effects Model
class LinearMixedEffectsModel(tf.keras.Model):
    def __init__(self, num_counties):
        super(LinearMixedEffectsModel, self).__init__()
        
        # Fixed effects
        self.beta_loc = self.add_weight(shape=(3, 2), initializer='zeros', trainable=True, name='beta_loc')
        self.beta_scale = self.add_weight(shape=(3, 2), initializer='ones', trainable=True, name='beta_scale')
        
        # Random effects
        self.u_loc = self.add_weight(shape=(num_counties, 2), initializer='zeros', trainable=True, name='u_loc')
        self.u_scale = self.add_weight(shape=(num_counties, 2), initializer='ones', trainable=True, name='u_scale')
        
        # Intercepts
        self.intercept = self.add_weight(shape=(2,), initializer='zeros', trainable=True, name='intercept')

    def call(self, inputs):
        if isinstance(inputs, dict):
            d0, d1, d2, county = inputs['d0'], inputs['d1'], inputs['d2'], inputs['county']
        else:
            d0, d1, d2, county = inputs
        
        # Sample from variational posteriors for fixed effects
        beta = self.beta_loc + tf.random.normal(self.beta_loc.shape) * tf.nn.softplus(self.beta_scale)
        
        # Sample from variational posteriors for random effects
        u = tf.gather(self.u_loc + tf.random.normal(self.u_loc.shape) * tf.nn.softplus(self.u_scale), tf.cast(county, tf.int32))
        
        # Fixed effects
        X = tf.stack([d0, d1, d2], axis=1)
        
        # Linear predictor
        linear_predictor = self.intercept + tf.matmul(X, beta) + u

        return linear_predictor

# Step 3: Define the Loss Function
def neg_log_likelihood(y_true, y_pred):
    y_true = tf.reshape(y_true, [-1, 2])  # [batch_size, 2]
    y_pred = tf.reshape(y_pred, [-1, 2])  # [batch_size, 2]
    
    # Assuming Gaussian likelihood
    return -tf.reduce_mean(tfd.Normal(loc=y_pred, scale=1.0).log_prob(y_true))

# Step 4: Train the Model
def train_model(train_path):
    df_scaled, scaler = load_and_preprocess_data(train_path)

    print("load and preprocess done")
    print("df scaled head ", df_scaled.head())

    num_counties = df_scaled['county'].nunique()  # Number of unique counties
    model = LinearMixedEffectsModel(num_counties)

    def combined_loss(y_true, y_pred):
        nll = neg_log_likelihood(y_true, y_pred)
        kl_divergence = (tf.reduce_sum(tfp.distributions.kl_divergence(
            tfd.Normal(model.beta_loc, tf.nn.softplus(model.beta_scale)),
            tfd.Normal(0, 1))) +
            tf.reduce_sum(tfp.distributions.kl_divergence(
                tfd.Normal(model.u_loc, tf.nn.softplus(model.u_scale)),
                tfd.Normal(0, 1))))
        return nll + kl_divergence

    print("model loss defined")
    model.compile(optimizer=tf.optimizers.Adam(), loss=combined_loss)

    county_indices = df_scaled['county'].astype('category').cat.codes.values  # [num_samples]
    features = (df_scaled['d0'].values, df_scaled['d1'].values, df_scaled['d2'].values, county_indices)
    targets = df_scaled[['change_f0', 'change_f1']].values

    model.fit(x=features, y=targets, epochs=100, batch_size=32)

    # Print learned parameters
    print("\nLearned Parameters:")
    print("Fixed Effects (Beta):")
    print("Beta Location:", model.beta_loc.numpy())
    print("Beta Scale:", tf.nn.softplus(model.beta_scale).numpy())
    print("\nRandom Effects (U):")
    print("U Location:", model.u_loc.numpy())
    print("U Scale:", tf.nn.softplus(model.u_scale).numpy())
    print("\nIntercepts:", model.intercept.numpy())

    return model, scaler

# Step 5: Prediction and Saving Results
def predict_and_save(model, scaler, test_path):
    test_df = pd.read_excel(test_path)
    
    test_features = test_df[['d0', 'd1', 'd2']]
    test_features_scaled = scaler.transform(test_features)  # [num_test_samples, 3]
    
    # Check if 'County' column exists
    if 'County' in test_df.columns:
        test_county_indices = test_df['County'].astype('category').cat.codes.values  # [num_test_samples]
    else:
        print("Warning: 'County' column not found in test data. Using default county index 0.")
        test_county_indices = np.zeros(len(test_df), dtype=int)  # Use county index 0 for all samples

    # Create a dictionary of inputs
    test_inputs = {
        'd0': test_features_scaled[:, 0],
        'd1': test_features_scaled[:, 1],
        'd2': test_features_scaled[:, 2],
        'county': test_county_indices
    }

    # Make predictions
    predictions = model(test_inputs)  # [num_test_samples, 2]
    change_f0_predictions, change_f1_predictions = predictions[:, 0], predictions[:, 1]

    # Calculate new f0 and f1 values
    test_df['f0'] = test_df['i0'] * (1 + change_f0_predictions.numpy())
    test_df['f1'] = test_df['i1'] * (1 + change_f1_predictions.numpy())

    new_test_path = test_path.replace('.xlsx', '_with_predictions.xlsx')
    test_df.to_excel(new_test_path, index=False)
    print(f"Predictions saved to {new_test_path}")

# Step 6: Train and Predict
print("\nTraining model for removed data:")
model_removed, scaler_removed = train_model(r'C:\Users\justi\Dropbox\Projects\Politics\nc-data-analysis\data\removed-training.xlsx')
print("step 2")
predict_and_save(model_removed, scaler_removed, r'C:\Users\justi\Dropbox\Projects\Politics\nc-data-analysis\data\added-inference.xlsx')

print("\nTraining model for added data:")
model_added, scaler_added = train_model(r'C:\Users\justi\Dropbox\Projects\Politics\nc-data-analysis\data\added-training.xlsx')
print("step 2")
predict_and_save(model_added, scaler_added, r'C:\Users\justi\Dropbox\Projects\Politics\nc-data-analysis\data\removed-inference.xlsx')