# Growth Mixture Model with Time-Varying Covariates

Extends
[`gmm_survey`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)
with comprehensive support for time-varying covariates (TVCs). TVCs can
have direct effects on outcomes, indirect effects on growth parameters,
and can interact with latent class membership.

## Usage

``` r
gmm_survey_tvc(
  data,
  id,
  time,
  outcome,
  n_classes,
  tvc,
  growth_model = "linear",
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  covariates = NULL,
  tvc_effects = c("direct", "indirect", "both", "interaction"),
  tvc_lag = 0,
  center_tvc = TRUE,
  tvc_by_class = FALSE,
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

- tvc:

  Formula specifying time-varying covariates. Variables must vary within
  individuals over time (e.g., `~ ses + parental_monitoring`)

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

- tvc_effects:

  Character string specifying how TVCs affect the model:

  "direct"

  :   TVCs directly predict outcome at each time point (default)

  "indirect"

  :   TVCs affect growth parameters (slopes)

  "both"

  :   Both direct and indirect effects

  "interaction"

  :   TVCs moderate class-specific trajectories

- tvc_lag:

  Integer specifying lag for TVCs (0 = contemporaneous, 1 = lagged once,
  etc.)

- center_tvc:

  Logical; center time-varying covariates? (default = TRUE)

- tvc_by_class:

  Logical; allow TVC effects to differ by class? (default = FALSE)

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

An S4 object of class `SurveyMixrTVC` (extends `SurveyMixr`) with
additional slots:

- tvc_effects:

  Data frame with TVC effect estimates for each class

- tvc_formula:

  Formula specifying time-varying covariates

- tvc_type:

  Type of TVC effects modeled

- tvc_centered_values:

  Centered covariate values used in estimation

## Details

\*\*Model Specifications:\*\*

\*\*1. Direct Effects Model:\*\* \$\$Y\_{it} = \beta\_{0k} + \beta\_{1k}
t + \gamma_k X\_{it} + \epsilon\_{it}\$\$

where \\X\_{it}\\ is the time-varying covariate and \\\gamma_k\\ is its
class-specific effect on the outcome.

\*\*2. Indirect Effects Model:\*\* \$\$Y\_{it} = \beta\_{0k} +
(\beta\_{1k} + \delta_k \bar{X}\_i) t + \epsilon\_{it}\$\$

where \\\bar{X}\_i\\ is the individual mean of the TVC and \\\delta_k\\
represents how the TVC affects the growth rate.

\*\*3. Both Effects Model:\*\* \$\$Y\_{it} = \beta\_{0k} +
(\beta\_{1k} + \delta_k \bar{X}\_i) t + \gamma_k (X\_{it} -
\bar{X}\_i) + \epsilon\_{it}\$\$

This separates between-person effects (\\\delta_k\\) from within-person
effects (\\\gamma_k\\).

\*\*4. Interaction Model:\*\* \$\$Y\_{it} = \beta\_{0k} + \beta\_{1k}
t + \gamma_k X\_{it} + \lambda_k (t \times X\_{it}) + \epsilon\_{it}\$\$

where \\\lambda_k\\ captures how the TVC moderates the trajectory slope.

\*\*Time-Varying vs Time-Invariant:\*\*

\- \*\*Time-invariant\*\*: Constant for each individual (e.g., sex,
baseline SES) - \*\*Time-varying\*\*: Changes within individuals (e.g.,
parental monitoring, stress)

The function automatically detects which covariates are time-varying by
checking for within-individual variance.

\*\*Centering:\*\*

When `center_tvc = TRUE`, covariates are centered at their grand mean.
This improves interpretability and can aid convergence. For "both"
effects, person-mean centering is used to separate within- and
between-person effects.

\*\*Lagged Effects:\*\*

Set `tvc_lag > 0` to examine lagged effects of TVCs: - `tvc_lag = 1`:
Previous time point predicts current outcome - `tvc_lag = 2`: Two time
points back predicts current outcome

## References

Curran, P. J., & Bauer, D. J. (2011). The disaggregation of
within-person and between-person effects in longitudinal models of
change. \*Annual Review of Psychology\*, 62, 583-619.

Hoffman, L. (2015). \*Longitudinal Analysis: Modeling Within-Person
Fluctuation and Change\*. New York: Routledge.

Wang, L. P., & Maxwell, S. E. (2015). On disaggregating between-person
and within-person effects with longitudinal data using multilevel
models. \*Psychological Methods\*, 20(1), 63-83.

## Examples

``` r
# Note: Time-varying covariate modeling is under development; this
# example will become runnable once the implementation is complete.
# Simulate data with covariates
# set.seed(999)
# sim_data <- simulate_gmm_survey(
# n_individuals = 200,
# n_times = 4,
# n_classes = 2,
# covariates = TRUE,
# design = "stratified_cluster",
# n_strata = 2,
# n_clusters = 20,
# seed = 999
# )

# Direct effects: covariate directly predicts outcome
# fit_direct <- gmm_survey_tvc(
# data = sim_data,
# id = "id",
# time = "time",
# outcome = "outcome",
# n_classes = 2,
# tvc = ~ baseline_risk,
# tvc_effects = "direct",
# starts = 20
# )

# Both within- and between-person effects
# fit_both <- gmm_survey_tvc(
# data = sim_data,
# id = "id",
# time = "time",
# outcome = "outcome",
# n_classes = 2,
# tvc = ~ baseline_risk,
# tvc_effects = "both",
# starts = 20
# )

# Extract TVC effects
# tvc_effects <- extract_tvc_effects(fit_both)
# print(tvc_effects)
```
