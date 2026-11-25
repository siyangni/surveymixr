# Extract Information Criteria

Extracts all information criteria from a fitted model or model selection
object.

## Usage

``` r
extract_fit_indices(object)
```

## Arguments

- object:

  Either a `SurveyMixr` or `SurveyMixrSelect` object

## Value

Data frame with information criteria

## Examples

``` r
# \donttest{
data(mcs_simulated)
set.seed(123)
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 2,
                  starts = 5, verbose = FALSE)
extract_fit_indices(fit)
#>   n_classes    loglik      aic      bic     abic   entropy n_params
#> 1         2 -49783.76 99581.53 99627.15 99604.91 0.9984752        7
# }
```
