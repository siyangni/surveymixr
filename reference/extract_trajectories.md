# Extract Trajectories by Class

Extracts predicted trajectories for a specific latent class.

## Usage

``` r
extract_trajectories(object, class = 1, time_range = NULL)
```

## Arguments

- object:

  A `SurveyMixr` object

- class:

  Integer specifying which class (default: 1)

- time_range:

  Optional numeric vector of time points for prediction

## Value

Data frame with time and predicted values

## Examples

``` r
# \donttest{
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 3, starts = 10)
#> Validating inputs...
#> Preparing data...
#>   N = 5000 individuals
#>   T = 6 time points
#>   Time scores: 3, 5, 7, 11, 14, 17
#> 
#> Running 10 random starts with 3 classes...
#> 
#> Selecting best solution...
#>   Best logLik: -48876.0278
#>   Replicated 1 times
#>   10/10 starts converged
#> Warning: Best log-likelihood not replicated. Consider increasing 'starts'.
#> 
#> Computing survey-adjusted standard errors...
#> Computing fit indices...
#> 
#> Completed in 51.4 seconds

traj_class1 <- extract_trajectories(fit, class = 1)
# }
```
