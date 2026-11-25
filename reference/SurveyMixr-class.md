# S4 Class Definition for surveymixr Objects

The `SurveyMixr` class contains results from growth mixture model
estimation with complex survey design.

## Slots

- `call`:

  The original function call

- `model_info`:

  List containing model specifications

- `parameters`:

  List of parameter estimates (class-specific growth parameters)

- `class_proportions`:

  Weighted and unweighted class proportions

- `posterior_probs`:

  Matrix of posterior probabilities (N x K)

- `class_assignments`:

  Vector of most likely class assignments

- `standard_errors`:

  List of standard errors (survey-adjusted)

- `vcov_matrix`:

  Variance-covariance matrix with survey adjustment

- `fit_indices`:

  List of fit statistics (logLik, AIC, BIC, aBIC, entropy)

- `convergence_info`:

  List with convergence diagnostics

- `random_starts`:

  List tracking all random starts

- `survey_design`:

  List containing survey design information

- `data`:

  Original data (optionally stored)

- `computation_time`:

  Time taken for estimation
