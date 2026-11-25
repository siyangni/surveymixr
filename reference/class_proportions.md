# Class Proportions with Confidence Intervals

Extracts class proportions with survey-adjusted confidence intervals.

## Usage

``` r
class_proportions(object, weighted = TRUE, ci_level = 0.95)
```

## Arguments

- object:

  A `SurveyMixr` object

- weighted:

  Logical, return weighted proportions? (default: TRUE)

- ci_level:

  Confidence level (default: 0.95)

## Value

Data frame with class proportions and confidence intervals

## Details

Class proportions are estimated from the mixture model. When survey
weights are used, weighted proportions better represent the population.
Confidence intervals account for survey design (clustering,
stratification).

## Examples

``` r
# \donttest{
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 3,
                  weights = "weight", starts = 10)
#> Validating inputs...
#> Validating survey design...
#> Warning: Survey design warnings:
#>   262 potential outliers (>3 SD from mean)
#> 
#> Run validate_survey_data() for full details.
#> Preparing data...
#>   N = 5000 individuals
#>   T = 6 time points
#>   Time scores: 3, 5, 7, 11, 14, 17
#>   Survey weights: range = [0.30, 2.16], mean = 1.00
#> 
#> Running 10 random starts with 3 classes...
#> 
#> Selecting best solution...
#>   Best logLik: -48800.8339
#>   Replicated 1 times
#>   10/10 starts converged
#> Warning: Best log-likelihood not replicated. Consider increasing 'starts'.
#> 
#> Computing survey-adjusted standard errors...
#> Computing fit indices...
#> 
#> Completed in 186.8 seconds

class_proportions(fit)
#>   class proportion          se  lower_ci  upper_ci n_assigned  percent
#> 1     1  0.5498861 0.007035785 0.5360963 0.5636760       2906 54.98861
#> 2     2  0.1464536 0.005000099 0.1366536 0.1562536        734 14.64536
#> 3     3  0.3036603 0.006503087 0.2909144 0.3164061       1360 30.36603
# }
```
