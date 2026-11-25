# Automated LMR Testing Across Multiple Models

Performs sequential LMR tests to compare models with 1 to K classes.
This is integrated into
[`gmm_select`](https://siyangni.github.io/surveymixr/reference/gmm_select.md)
but can be called separately.

## Usage

``` r
lmr_sequential(model_list, adjusted = TRUE)
```

## Arguments

- model_list:

  List of fitted `SurveyMixr` objects with increasing number of classes

- adjusted:

  Logical; use adjusted LMR?

## Value

Data frame with LMR test results for each comparison

## Examples

``` r
# \donttest{
# Quick example with 1-2 classes (reduced starts for speed)
data(mcs_simulated)
set.seed(123)

models <- lapply(1:2, function(k) {
  gmm_survey(
    data = mcs_simulated,
    id = "id", time = "age", outcome = "selfcontrol",
    n_classes = k, starts = 5, verbose = FALSE
  )
})

# Run LMR tests
lmr_results <- lmr_sequential(models, adjusted = TRUE)
print(lmr_results)
#> 
#> Sequential Lo-Mendell-Rubin Tests
#> ======================================================================
#> 
#>  comparison almr_statistic df p_value_adjusted significant
#>      2 vs 1          19207  4                0        TRUE
#> 
#> Recommendation based on aLMR:
#>   2-class model recommended
#>   (last significant improvement)
#> 
#> Note: Consider also examining BIC, entropy, and BLRT
#> for comprehensive model selection.

# For production analysis, use classes 1:5 and starts = 200
# }
```
