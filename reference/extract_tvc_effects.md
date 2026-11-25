# Extract Time-Varying Covariate Effects

Extracts estimated effects of time-varying covariates from a fitted
model.

## Usage

``` r
extract_tvc_effects(object, effect_type = "all", class = "all")
```

## Arguments

- object:

  Fitted `SurveyMixrTVC` object

- effect_type:

  Character: "direct", "indirect", or "both"

- class:

  Optional; specific class to extract (default = "all")

## Value

Data frame with TVC effect estimates, standard errors, and p-values

## Examples

``` r
# Note: Time-varying covariate modeling is under development; this
# example will become runnable once the implementation is complete.
# Simulate data with covariates
# set.seed(789)
# sim_data <- simulate_gmm_survey(
# n_individuals = 200,
# n_times = 4,
# n_classes = 3,
# covariates = TRUE,
# seed = 789
# )

# fit <- gmm_survey_tvc(
# data = sim_data,
# id = "id", time = "time", outcome = "outcome",
# n_classes = 3, tvc = ~ baseline_risk, tvc_effects = "both", starts = 20
# )

# Extract all TVC effects
# effects <- extract_tvc_effects(fit)
# print(effects)

# Extract for specific class
# effects_c1 <- extract_tvc_effects(fit, class = 1)
```
