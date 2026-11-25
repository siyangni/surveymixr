# Test Time-Varying Covariate Effects

Performs Wald tests for significance of TVC effects, both overall and
class-specific.

## Usage

``` r
test_tvc_effects(
  object,
  covariate,
  test = c("both", "overall", "class_specific")
)
```

## Arguments

- object:

  Fitted `SurveyMixrTVC` object

- covariate:

  Name of TVC to test

- test:

  Character: "overall" (test across all classes), "class_specific" (test
  within each class), or "both"

## Value

List with test statistics and p-values

## Examples

``` r
# Note: Time-varying covariate modeling is under development; this
# example will become runnable once the implementation is complete.
# fit <- gmm_survey_tvc(
# data = mcs_simulated,
# id = "id", time = "age", outcome = "selfcontrol",
# n_classes = 3, tvc = ~ ses, starts = 100
# )

# Test significance of SES effect
# test_results <- test_tvc_effects(fit, covariate = "ses")
# print(test_results)
```
