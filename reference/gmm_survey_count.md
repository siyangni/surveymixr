# Growth Mixture Model for Count Outcomes

Fits growth mixture models with count outcomes using Poisson or negative
binomial regression within each latent class.

## Usage

``` r
gmm_survey_count(
  data,
  id,
  time,
  outcome,
  n_classes,
  growth_model = "linear",
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  covariates = NULL,
  count_model = c("poisson", "negative_binomial", "zero_inflated"),
  offset = NULL,
  starts = 500,
  cores = parallel::detectCores() - 1,
  convergence_threshold = 1e-06,
  max_iterations = 1000,
  seed = NULL,
  verbose = TRUE
)
```

## Arguments

- data:

  Data frame in long format containing repeated measurements

- id:

  Character string specifying the individual ID variable name

- time:

  Character string specifying the time variable name

- outcome:

  Character string specifying the outcome variable name

- n_classes:

  Integer number of latent classes (default: 2)

- growth_model:

  Character string specifying growth model type: `"linear"` (default),
  `"quadratic"`, `"nonlinear"`, or `"free_basis"`

- strata:

  Character string specifying stratification variable (optional)

- cluster:

  Character string specifying cluster/PSU variable (optional)

- weights:

  Character string specifying sampling weights variable (optional)

- covariates:

  Character vector of time-varying covariate names (not yet implemented)

- count_model:

  Character: "poisson" (default), "negative_binomial", or
  "zero_inflated"

- offset:

  Optional offset variable (e.g., log exposure time)

- starts:

  Integer number of random starts (default: 500)

- cores:

  Integer number of CPU cores for parallel processing (default: 1)

- convergence_threshold:

  Numeric convergence criterion for EM algorithm (default: 1e-6)

- max_iterations:

  Integer maximum number of EM iterations (default: 1000)

- seed:

  Integer random seed for reproducibility (optional)

- verbose:

  Logical, print progress messages? (default: TRUE)

## Value

S4 object of class `SurveyMixr` with count-specific components

## Details

For count outcomes, the model uses: \$\$Y\_{it} \| C_i = k \sim
Poisson(\lambda\_{itk})\$\$ where \\\log(\lambda\_{itk}) = \eta\_{itk}\\
and \\\eta\_{itk}\\ includes growth parameters.

For zero-inflated models: \$\$P(Y\_{it} = 0 \| C_i = k) = \pi_k + (1 -
\pi_k) \times e^{-\lambda\_{itk}}\$\$ \$\$P(Y\_{it} = y \| C_i = k) =
(1 - \pi_k) \times Poisson(y; \lambda\_{itk}), \quad y \> 0\$\$

## Examples

``` r
# Note: Count outcome modeling is under development; this example will
# become runnable once the implementation is complete.
# Simulate count outcome data (e.g., number of delinquent acts)
# count_data <- simulate_gmm_survey(
# n_individuals = 1500,
# n_times = 6,
# n_classes = 3,

# design = "cluster",
# seed = 456
# )

# Convert continuous outcome to count data (non-negative integers)
# Shift to be positive then take absolute value and round to integers
# count_data$outcome <- as.integer(round(abs(count_data$outcome + 3)))

# Fit 3-class Poisson model
# fit_count <- gmm_survey_count(
# data = count_data,
# id = "id",
# time = "time",
# outcome = "outcome",
# n_classes = 3,
# cluster = "cluster",
# weights = "weight",
# starts = 200
# )

# summary(fit_count)
```
