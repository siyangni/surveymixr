# Convergence Diagnostics for Growth Mixture Models

Provides detailed convergence diagnostics including log-likelihood
distribution from multiple random starts, identification of local
maxima, and recommendations.

## Usage

``` r
diagnose_convergence(gmm_object, tolerance = 1e-04, plot = TRUE)
```

## Arguments

- gmm_object:

  A fitted `SurveyMixr` object from
  [`gmm_survey()`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)

- tolerance:

  Tolerance for identifying replicated solutions (default: 1e-4)

- plot:

  Logical, create diagnostic plot? (default: TRUE)

## Value

An S4 object of class
[`ConvergenceDiagnostics`](https://siyangni.github.io/surveymixr/reference/ConvergenceDiagnostics-class.md)
containing detailed convergence information

## Details

Multiple random starts are essential for growth mixture models because
the likelihood surface typically has multiple local maxima. This
function helps assess whether the best solution is trustworthy by:

- Tabulating log-likelihoods from all random starts

- Identifying how many times the best solution was replicated

- Detecting distinct local maxima

- Providing recommendations for improving convergence

**Guidelines:**

- Best solution should be replicated at least 2-3 times

- If not replicated, increase `starts` in
  [`gmm_survey()`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)

- Multiple distinct local maxima may indicate model instability

- Very different log-likelihoods suggest identifiability issues

## References

Hipp, J. R., & Bauer, D. J. (2006). Local solutions in the estimation of
growth mixture models. *Psychological Methods, 11*(1), 36-53.

## Examples

``` r
# \donttest{
data(mcs_simulated)
set.seed(123)
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 2, starts = 10,
                  verbose = FALSE)

diagnostics <- diagnose_convergence(fit, plot = FALSE)
print(diagnostics)
#> Convergence Diagnostics
#> =======================
#> 
#> Number of random starts: 10
#> Best log-likelihood: -49783.7649
#> 
#> Local maxima detected: 1
#> Top 5 solutions:
#>   rank    loglik n_times diff_from_best
#> 1    1 -49783.76      10              0
#> 
#> Warnings:
#>   - No convergence issues detected
#> 
#> Recommendations:
#>   - Model appears well-identified
# }
```
