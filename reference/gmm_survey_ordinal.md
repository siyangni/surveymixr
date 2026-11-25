# Growth Mixture Model for Ordinal Outcomes

Fits growth mixture models with ordinal outcomes using proportional odds
or adjacent category models within each latent class.

## Usage

``` r
gmm_survey_ordinal(
  data,
  id,
  time,
  outcome,
  n_classes,
  n_categories,
  growth_model = "linear",
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  covariates = NULL,
  ordinal_model = c("proportional_odds", "adjacent_category"),
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

- n_categories:

  Integer specifying number of ordered categories

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

- ordinal_model:

  Character: "proportional_odds" (default) or "adjacent_category"

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

S4 object of class `SurveyMixr` with ordinal-specific components

## Details

For ordinal outcomes with K categories (0, 1, ..., K-1), the
proportional odds model uses: \$\$P(Y\_{it} \leq j \| C_i = k) =
\Phi(\tau_j - \eta\_{itk})\$\$ where \\\tau_1 \< \tau_2 \< ... \<
\tau\_{K-1}\\ are threshold parameters and \\\eta\_{itk}\\ is the linear
predictor.

## Examples

``` r
# Example for ordinal outcomes (under development; not yet runnable)
# ordinal_data <- simulate_gmm_survey(n_individuals = 500, design = "srs")
# ordinal_data$outcome <- cut(ordinal_data$outcome, breaks = 5, labels = FALSE) - 1
#
# fit_ordinal <- gmm_survey_ordinal(
#   data = ordinal_data, id = "id", time = "time", outcome = "outcome",
#   n_classes = 2, n_categories = 5, starts = 50
# )
```
