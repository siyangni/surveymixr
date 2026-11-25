# Detect Separation in Latent Classes

Checks for perfect or quasi-perfect separation between latent classes,
which can cause estimation problems.

## Usage

``` r
diagnose_separation(object, threshold = 0.99)
```

## Arguments

- object:

  Fitted `SurveyMixr` object

- threshold:

  Minimum posterior probability considered "quasi-perfect" (default =
  0.99)

## Value

List with components:

- has_separation:

  Logical; is separation detected?

- separation_type:

  "none", "quasi", or "perfect"

- pct_extreme:

  Percentage of individuals with extreme probabilities

- class_sizes:

  Weighted and unweighted class sizes

- entropy:

  Classification entropy

- recommendation:

  Text recommendation

## Details

Perfect separation occurs when latent classes are completely
distinguished by observed variables, leading to: - Entropy approaching
1.0 - All posterior probabilities near 0 or 1 - Unstable parameter
estimates - Inflated standard errors

This function checks for: 1. \*\*Perfect separation\*\*: All individuals
assigned to classes with prob \> 0.999 2. \*\*Quasi-perfect
separation\*\*: Most individuals have extreme probabilities 3. \*\*Empty
classes\*\*: Classes with very few assigned members

## Examples

``` r
# \donttest{
# Quick example
data(mcs_simulated)
set.seed(123)

fit <- gmm_survey(
  data = mcs_simulated,
  id = "id", time = "age", outcome = "selfcontrol",
  n_classes = 2, starts = 5, verbose = FALSE
)

sep_check <- diagnose_separation(fit)
print(sep_check)
#> $has_separation
#> [1] TRUE
#> 
#> $separation_type
#> [1] "quasi"
#> 
#> $pct_extreme
#> [1] 99.68
#> 
#> $min_posterior_prob
#> [1] 0.6541604
#> 
#> $max_posterior_prob
#> [1] 1
#> 
#> $class_sizes
#> $class_sizes$unweighted
#> class_assignment
#>    1    2 
#> 4264  736 
#> 
#> $class_sizes$weighted
#> class_assignment
#>    1    2 
#> 4264  736 
#> 
#> $class_sizes$proportion
#> class_assignment
#>      1      2 
#> 0.8528 0.1472 
#> 
#> 
#> $entropy
#> [1] 0.9984752
#> 
#> $entropy_relative
#> [1] 0.9984752
#> 
#> $recommendation
#> [1] "Quasi-perfect separation detected. Results should be interpreted cautiously."
#> 
#> attr(,"class")
#> [1] "separation_diagnostics"
# }
```
