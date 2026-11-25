# Compare Classes on a Variable

Conducts statistical tests comparing latent classes on a specific
variable.

## Usage

``` r
compare_classes(object, var, test = "wald")
```

## Arguments

- object:

  A `SurveyMixr` object

- var:

  Character string, variable name (must be in original data)

- test:

  Character string: "wald" (default), "chisq", or "anova"

## Value

List containing test results

## Examples

``` r
# \donttest{
data(mcs_simulated)
set.seed(123)
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 2,
                  auxiliary = "baseline_risk",
                  keep_data = TRUE, starts = 5, verbose = FALSE)

compare_classes(fit, var = "baseline_risk", test = "wald")
#> $variable
#> [1] "baseline_risk"
#> 
#> $class_means
#>          1          2 
#>  0.2089789 -0.3486588 
#> 
#> $class_sds
#>         1         2 
#> 1.0035675 0.9856039 
#> 
#> $class_ns
#>    1    2 
#> 4264  736 
#> 
#> $test_statistic
#> [1] 199.8386
#> 
#> $df1
#> [1] 1
#> 
#> $df2
#> [1] 4998
#> 
#> $p_value
#> [1] 1.616729e-44
#> 
# }
```
